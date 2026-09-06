//
//  TimerViewModel.swift
//  PomodoroTimer
//

import ActivityKit
import AudioToolbox
import Foundation
import SwiftData
import UIKit
import UserNotifications

/// サウンドの選択肢。
enum SoundOption: String, CaseIterable {
    case bell
    case chime
    case alert
    case fanfare
    case tweet
    case none

    /// 表示名。
    var label: String {
        switch self {
        case .bell: "ベル"
        case .chime: "チャイム"
        case .alert: "アラート"
        case .fanfare: "ファンファーレ"
        case .tweet: "鳥のさえずり"
        case .none: "なし"
        }
    }

    /// システムサウンドID。なしの場合はnil。
    var soundID: SystemSoundID? {
        switch self {
        case .bell: 1016
        case .chime: 1025
        case .alert: 1005
        case .fanfare: 1304
        case .tweet: 1057
        case .none: nil
        }
    }
}

/// タイマーのフェーズ。
enum TimerPhase {
    /// 作業中。
    case work
    /// 短い休憩。
    case shortBreak
    /// 長い休憩。
    case longBreak

    /// フェーズの表示名。
    var label: String {
        switch self {
        case .work: "作業中"
        case .shortBreak: "休憩中"
        case .longBreak: "長い休憩中"
        }
    }
}

@Observable
final class TimerViewModel {
    // MARK: - タイマー設定（秒）

    /// 作業時間（秒）。
    var workDuration = 25 * 60
    /// 短い休憩時間（秒）。
    var shortBreakDuration = 5 * 60
    /// 長い休憩時間（秒）。
    var longBreakDuration = 15 * 60
    let pomodorosForLongBreak = 4

    // MARK: - 状態

    /// 残り時間（秒）。
    var remainingSeconds: Int
    /// タイマーのフェーズ。
    var phase: TimerPhase = .work
    /// タイマーが動作中かどうか。
    var isRunning = false
    /// 完了したポモドーロの回数。
    var completedCount = 0
    /// 設定シートを表示するかどうか。
    var showSettings = false
    /// 作業完了時のサウンド。
    var workCompletionSound: SoundOption = .chime {
        didSet { UserDefaults.standard.set(workCompletionSound.rawValue, forKey: "workCompletionSound") }
    }
    /// 休憩完了時のサウンド。
    var breakCompletionSound: SoundOption = .bell {
        didSet { UserDefaults.standard.set(breakCompletionSound.rawValue, forKey: "breakCompletionSound") }
    }

    // MARK: - 内部状態

    private var timer: Timer?
    private var sessionStartedAt: Date?
    private var modelContext: ModelContext?
    /// バックグラウンド移行時の時刻。
    private var backgroundEnteredAt: Date?
    /// 現在のLive Activity。
    private var currentActivity: Activity<PomodoroTimerAttributes>?

    // MARK: - 計算プロパティ

    /// 現在のフェーズの合計時間（秒）。
    var totalSeconds: Int {
        switch phase {
        case .work: workDuration
        case .shortBreak: shortBreakDuration
        case .longBreak: longBreakDuration
        }
    }

    /// プログレス（0.0〜1.0）。
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    /// 残り時間の表示文字列（"MM:SS"形式）。
    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// フェーズの色キー。
    var phaseColorKey: String {
        switch phase {
        case .work: "work"
        case .shortBreak: "shortBreak"
        case .longBreak: "longBreak"
        }
    }

    // MARK: - 初期化

    init() {
        remainingSeconds = 25 * 60

        if let raw = UserDefaults.standard.string(forKey: "workCompletionSound"),
           let sound = SoundOption(rawValue: raw) {
            workCompletionSound = sound
        }
        if let raw = UserDefaults.standard.string(forKey: "breakCompletionSound"),
           let sound = SoundOption(rawValue: raw) {
            breakCompletionSound = sound
        }
    }

    /// ModelContextを設定する。
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        cleanupStaleLiveActivities()
    }

    // MARK: - 操作

    /// タイマーを開始する。
    func start() {
        guard !isRunning else { return }
        isRunning = true
        UIApplication.shared.isIdleTimerDisabled = true

        if sessionStartedAt == nil, phase == .work {
            sessionStartedAt = Date()
        }

        requestNotificationPermission()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }

        if currentActivity == nil {
            startLiveActivity()
        } else {
            updateLiveActivity()
        }
    }

    /// タイマーを一時停止する。
    func pause() {
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
        timer?.invalidate()
        timer = nil
        updateLiveActivity()
    }

    /// タイマーをリセットする。
    func reset() {
        pause()
        endLiveActivity()
        phase = .work
        remainingSeconds = workDuration
        completedCount = 0
        sessionStartedAt = nil
    }

    /// 作業時間を更新する。
    func updateWorkDuration(minutes: Int) {
        workDuration = minutes * 60
        if !isRunning, phase == .work {
            remainingSeconds = workDuration
        }
    }

    /// 短い休憩時間を更新する。
    func updateShortBreakDuration(minutes: Int) {
        shortBreakDuration = minutes * 60
        if !isRunning, phase == .shortBreak {
            remainingSeconds = shortBreakDuration
        }
    }

    /// 長い休憩時間を更新する。
    func updateLongBreakDuration(minutes: Int) {
        longBreakDuration = minutes * 60
        if !isRunning, phase == .longBreak {
            remainingSeconds = longBreakDuration
        }
    }

    // MARK: - バックグラウンド対応

    /// バックグラウンド移行時に呼び出す。
    func handleBackgroundEntry() {
        guard isRunning else { return }
        backgroundEnteredAt = Date()
        timer?.invalidate()
        timer = nil
    }

    /// フォアグラウンド復帰時に呼び出す。
    func handleForegroundEntry() {
        guard isRunning, let backgroundEnteredAt else { return }
        let elapsed = Int(Date().timeIntervalSince(backgroundEnteredAt))
        self.backgroundEnteredAt = nil

        if elapsed >= remainingSeconds {
            remainingSeconds = 0
            timerCompleted()
        } else {
            remainingSeconds -= elapsed
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
            updateLiveActivity()
        }
    }

    // MARK: - 内部処理

    private func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1

        if remainingSeconds == 0 {
            timerCompleted()
        }
    }

    /// タイマー完了時の処理。
    private func timerCompleted() {
        pause()

        switch phase {
        case .work:
            saveSession()
            completedCount += 1
            playSound(workCompletionSound)
            if completedCount % pomodorosForLongBreak == 0 {
                phase = .longBreak
                remainingSeconds = longBreakDuration
                sendNotification(title: "作業完了", body: "長い休憩を取りましょう（\(longBreakDuration / 60)分）")
            } else {
                phase = .shortBreak
                remainingSeconds = shortBreakDuration
                sendNotification(title: "作業完了", body: "短い休憩を取りましょう（\(shortBreakDuration / 60)分）")
            }
        case .shortBreak, .longBreak:
            playSound(breakCompletionSound)
            phase = .work
            remainingSeconds = workDuration
            sessionStartedAt = nil
            sendNotification(title: "休憩終了", body: "作業を再開しましょう")
        }

        updateLiveActivity()
    }

    /// 完了したセッションをSwiftDataに保存する。
    private func saveSession() {
        guard let modelContext else { return }
        let startedAt = sessionStartedAt ?? Date()
        let session = PomodoroSession(
            startedAt: startedAt,
            durationSeconds: workDuration,
            completedAt: Date()
        )
        modelContext.insert(session)
        sessionStartedAt = nil
    }

    // MARK: - サウンド

    /// サウンドを再生する。
    private func playSound(_ option: SoundOption) {
        guard let soundID = option.soundID else { return }
        AudioServicesPlaySystemSound(soundID)
    }

    /// プレビュー再生する。
    func previewSound(_ option: SoundOption) {
        playSound(option)
    }

    // MARK: - 通知

    /// 通知権限をリクエストする。
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// ローカル通知を送信する。
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Live Activity

    /// Live Activityを開始する。
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = makeLiveActivityState()
        let content = ActivityContent(state: state, staleDate: nil)
        do {
            currentActivity = try Activity<PomodoroTimerAttributes>.request(
                attributes: PomodoroTimerAttributes(),
                content: content,
                pushType: nil
            )
        } catch {
            print("Live Activity開始エラー: \(error)")
        }
    }

    /// Live Activityを更新する。
    private func updateLiveActivity() {
        guard let currentActivity else { return }

        let state = makeLiveActivityState()
        let content = ActivityContent(state: state, staleDate: nil)
        Task {
            await currentActivity.update(content)
        }
    }

    /// Live Activityを終了する。
    private func endLiveActivity() {
        guard let currentActivity else { return }

        let state = makeLiveActivityState()
        let content = ActivityContent(state: state, staleDate: nil)
        Task {
            await currentActivity.end(content, dismissalPolicy: .immediate)
        }
        self.currentActivity = nil
    }

    /// 前回のstaleなLive Activityをクリーンアップする。
    private func cleanupStaleLiveActivities() {
        for activity in Activity<PomodoroTimerAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    /// 現在の状態からLive ActivityのContentStateを生成する。
    private func makeLiveActivityState() -> PomodoroTimerAttributes.ContentState {
        let isPaused = !isRunning
        let endTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        return PomodoroTimerAttributes.ContentState(
            endTime: endTime,
            phaseLabel: phase.label,
            phaseColorKey: phaseColorKey,
            isPaused: isPaused,
            pausedRemainingSeconds: isPaused ? remainingSeconds : nil,
            completedCount: completedCount
        )
    }
}
