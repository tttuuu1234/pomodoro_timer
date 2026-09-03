//
//  CircularProgressView.swift
//  PomodoroTimer
//

import SwiftUI

struct CircularProgressView: View {
    /// プログレス（0.0〜1.0）。
    let progress: Double
    /// フェーズに応じたリングの色。
    let color: Color
    /// リングの太さ。
    let lineWidth: CGFloat

    init(progress: Double, color: Color, lineWidth: CGFloat = 12) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // 背景リング
            Circle()
                .stroke(color.opacity(0.1), lineWidth: lineWidth)

            // 前景リング
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.6), color]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.4), radius: 8)
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

#Preview {
    CircularProgressView(progress: 0.65, color: .red)
        .frame(width: 200, height: 200)
        .padding()
}
