//
//  PomodoroSession.swift
//  PomodoroTimer
//

import Foundation
import SwiftData

@Model
final class PomodoroSession {
    /// セッション開始日時。
    var startedAt: Date
    /// 作業した秒数。
    var durationSeconds: Int
    /// セッション完了日時。
    var completedAt: Date

    init(startedAt: Date, durationSeconds: Int, completedAt: Date) {
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.completedAt = completedAt
    }
}
