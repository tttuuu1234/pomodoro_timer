//
//  PomodoroTimerAttributes.swift
//  PomodoroTimer
//

import ActivityKit
import Foundation

/// Live Activityの属性定義。
struct PomodoroTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// タイマー終了予定時刻。
        var endTime: Date
        /// フェーズの表示ラベル（"作業中" / "休憩中" / "長い休憩中"）。
        var phaseLabel: String
        /// フェーズの色キー（"work" / "shortBreak" / "longBreak"）。
        var phaseColorKey: String
        /// 一時停止中かどうか。
        var isPaused: Bool
        /// 一時停止中の残り秒数。
        var pausedRemainingSeconds: Int?
        /// 完了したポモドーロの回数。
        var completedCount: Int
    }
}
