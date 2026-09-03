//
//  SettingsView.swift
//  PomodoroTimer
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: TimerViewModel

    /// 作業時間（分）。
    private var workMinutes: Int { viewModel.workDuration / 60 }
    /// 短い休憩時間（分）。
    private var shortBreakMinutes: Int { viewModel.shortBreakDuration / 60 }
    /// 長い休憩時間（分）。
    private var longBreakMinutes: Int { viewModel.longBreakDuration / 60 }

    var body: some View {
        NavigationStack {
            List {
                // 作業時間
                Section {
                    Stepper(
                        "\(workMinutes)分",
                        value: Binding(
                            get: { workMinutes },
                            set: { viewModel.updateWorkDuration(minutes: $0) }
                        ),
                        in: 1...60,
                        step: 5
                    )
                } header: {
                    Label("作業時間", systemImage: "flame.fill")
                        .foregroundStyle(Color.workPhase)
                }

                // 短い休憩
                Section {
                    Stepper(
                        "\(shortBreakMinutes)分",
                        value: Binding(
                            get: { shortBreakMinutes },
                            set: { viewModel.updateShortBreakDuration(minutes: $0) }
                        ),
                        in: 1...30,
                        step: 1
                    )
                } header: {
                    Label("短い休憩", systemImage: "leaf.fill")
                        .foregroundStyle(Color.shortBreakPhase)
                }

                // 長い休憩
                Section {
                    Stepper(
                        "\(longBreakMinutes)分",
                        value: Binding(
                            get: { longBreakMinutes },
                            set: { viewModel.updateLongBreakDuration(minutes: $0) }
                        ),
                        in: 1...60,
                        step: 5
                    )
                } header: {
                    Label("長い休憩", systemImage: "cup.and.saucer.fill")
                        .foregroundStyle(Color.longBreakPhase)
                }

                // 作業完了サウンド
                Section {
                    Picker("サウンド", selection: $viewModel.workCompletionSound) {
                        ForEach(SoundOption.allCases, id: \.self) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .onChange(of: viewModel.workCompletionSound) { _, newValue in
                        viewModel.previewSound(newValue)
                    }
                } header: {
                    Label("作業完了サウンド", systemImage: "speaker.wave.2.fill")
                        .foregroundStyle(Color.workPhase)
                }

                // 休憩完了サウンド
                Section {
                    Picker("サウンド", selection: $viewModel.breakCompletionSound) {
                        ForEach(SoundOption.allCases, id: \.self) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .onChange(of: viewModel.breakCompletionSound) { _, newValue in
                        viewModel.previewSound(newValue)
                    }
                } header: {
                    Label("休憩完了サウンド", systemImage: "speaker.wave.2.fill")
                        .foregroundStyle(Color.shortBreakPhase)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        viewModel.showSettings = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SettingsView(viewModel: TimerViewModel())
}
