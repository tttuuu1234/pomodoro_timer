//
//  TimerView.swift
//  PomodoroTimer
//

import SwiftUI
import SwiftData

// MARK: - フェーズカラー

extension Color {
    /// 作業フェーズの色。
    static let workPhase = Color(red: 0.93, green: 0.55, blue: 0.20)
    /// 短い休憩フェーズの色。
    static let shortBreakPhase = Color(red: 0.30, green: 0.75, blue: 0.55)
    /// 長い休憩フェーズの色。
    static let longBreakPhase = Color(red: 0.35, green: 0.55, blue: 0.85)
}

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = TimerViewModel()

    /// フェーズに応じた色。
    private var phaseColor: Color {
        switch viewModel.phase {
        case .work: .workPhase
        case .shortBreak: .shortBreakPhase
        case .longBreak: .longBreakPhase
        }
    }

    var body: some View {
        ZStack {
            // グラデーション背景
            LinearGradient(
                colors: [phaseColor.opacity(0.12), phaseColor.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // フェーズ表示ラベル
                Text(viewModel.phase.label)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(phaseColor)

                // 円形プログレスバー + 残り時間
                ZStack {
                    CircularProgressView(progress: viewModel.progress, color: phaseColor, lineWidth: 14)
                        .frame(width: 260, height: 260)
                        .shadow(color: phaseColor.opacity(0.2), radius: 16)

                    VStack(spacing: 4) {
                        Text("残り")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(viewModel.timeString)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .contentTransition(.numericText())
                    }
                }

                // 完了ポモドーロ数
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(phaseColor)
                    Text("\(viewModel.completedCount)")
                        .fontWeight(.medium)
                    Text("ポモドーロ完了")
                        .foregroundStyle(.secondary)
                }
                .font(.body)

                Spacer()

                // 操作ボタン
                HStack(spacing: 24) {
                    // リセットボタン
                    Button {
                        viewModel.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    // 開始/一時停止ボタン
                    Button {
                        if viewModel.isRunning {
                            viewModel.pause()
                        } else {
                            viewModel.start()
                        }
                    } label: {
                        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .frame(width: 72, height: 72)
                            .foregroundStyle(.white)
                            .background(
                                LinearGradient(
                                    colors: [phaseColor, phaseColor.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                in: Circle()
                            )
                            .shadow(color: phaseColor.opacity(0.4), radius: 8, y: 4)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.phase)
        .overlay(alignment: .topTrailing) {
            // 設定ボタン
            Button {
                viewModel.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(phaseColor.opacity(0.6))
                    .padding()
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                viewModel.handleBackgroundEntry()
            case .active:
                viewModel.handleForegroundEntry()
            default:
                break
            }
        }
    }
}

#Preview {
    TimerView()
        .modelContainer(for: PomodoroSession.self, inMemory: true)
}
