//
//  PomodoroTimerLiveActivity.swift
//  PomodoroTimerWidgets
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - フェーズカラー（Widget Extension用）

extension Color {
    /// フェーズの色キーからColorを返す。
    static func phaseColor(for key: String) -> Color {
        switch key {
        case "work": Color(red: 0.93, green: 0.55, blue: 0.20)
        case "shortBreak": Color(red: 0.30, green: 0.75, blue: 0.55)
        case "longBreak": Color(red: 0.35, green: 0.55, blue: 0.85)
        default: .orange
        }
    }
}

// MARK: - フェーズアイコン

/// フェーズの色キーからSF Symbolsアイコン名を返す。
private func phaseIcon(for key: String) -> String {
    switch key {
    case "work": "flame.fill"
    case "shortBreak": "cup.and.saucer.fill"
    case "longBreak": "moon.fill"
    default: "timer"
    }
}

// MARK: - Live Activity

struct PomodoroTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroTimerAttributes.self) { context in
            // ロック画面表示
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.phaseLabel, systemImage: phaseIcon(for: context.state.phaseColorKey))
                        .font(.caption)
                        .foregroundStyle(Color.phaseColor(for: context.state.phaseColorKey))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.phaseColor(for: context.state.phaseColorKey))
                        Text("\(context.state.completedCount)")
                    }
                    .font(.caption)
                }
                DynamicIslandExpandedRegion(.center) {
                    timerText(context: context)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.phaseColor(for: context.state.phaseColorKey))
                }
            } compactLeading: {
                Image(systemName: phaseIcon(for: context.state.phaseColorKey))
                    .foregroundStyle(Color.phaseColor(for: context.state.phaseColorKey))
            } compactTrailing: {
                timerText(context: context)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.phaseColor(for: context.state.phaseColorKey))
            } minimal: {
                Image(systemName: phaseIcon(for: context.state.phaseColorKey))
                    .foregroundStyle(Color.phaseColor(for: context.state.phaseColorKey))
            }
        }
    }

    // MARK: - ロック画面

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<PomodoroTimerAttributes>) -> some View {
        let color = Color.phaseColor(for: context.state.phaseColorKey)

        HStack {
            // 左: フェーズアイコン + ラベル + ポモドーロ数
            VStack(alignment: .leading, spacing: 4) {
                Label(context.state.phaseLabel, systemImage: phaseIcon(for: context.state.phaseColorKey))
                    .font(.headline)
                    .foregroundStyle(color)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(color)
                    Text("\(context.state.completedCount) ポモドーロ")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            Spacer()

            // 右: カウントダウン
            VStack(alignment: .trailing, spacing: 2) {
                timerText(context: context)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))

                if context.state.isPaused {
                    Text("一時停止中")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    // MARK: - タイマーテキスト

    @ViewBuilder
    private func timerText(context: ActivityViewContext<PomodoroTimerAttributes>) -> some View {
        if context.state.isPaused, let remaining = context.state.pausedRemainingSeconds {
            let minutes = remaining / 60
            let seconds = remaining % 60
            Text(String(format: "%02d:%02d", minutes, seconds))
        } else {
            Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
        }
    }
}
