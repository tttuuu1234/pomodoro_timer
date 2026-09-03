# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ビルド・テストコマンド

Xcodeプロジェクト（SPM Package.swiftなし）。コマンドラインでは `xcodebuild` を使用する。

```bash
# ビルド
xcodebuild -project PomodoroTimer.xcodeproj -scheme PomodoroTimer -destination 'platform=iOS Simulator,name=iPhone 16' build

# ユニットテスト実行（Swift Testingフレームワーク）
xcodebuild -project PomodoroTimer.xcodeproj -scheme PomodoroTimer -destination 'platform=iOS Simulator,name=iPhone 16' test

# UIテストのみ実行
xcodebuild -project PomodoroTimer.xcodeproj -scheme PomodoroTimer -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PomodoroTimerUITests test

# 単一テスト実行
xcodebuild -project PomodoroTimer.xcodeproj -scheme PomodoroTimer -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PomodoroTimerTests/PomodoroTimerTests/testExample test
```

## アーキテクチャ

- **対象:** iOS 26.2+、iPhone・iPad対応
- **UI:** SwiftUI（`NavigationSplitView`によるアダプティブレイアウト）
- **データ:** SwiftData（ローカル永続ストレージ）
- **並行処理:** デフォルトアクター分離は`MainActor`、Approachable Concurrency有効
- **テスト:** ユニットテストはSwift Testing（`@Test`マクロ）、UIテストはXCTest
- **依存:** 外部依存なし（SwiftUI、SwiftData、Foundationのみ）

## ブランチ規則

- 作業ブランチはmainブランチから作成する
- 機能開発: `feat/{Issue番号}`（例: `feat/1`）
- バグ修正: `fix/{Issue番号}`（例: `fix/2`）
- リファクタリング: `refactor/{Issue番号}`（例: `refactor/3`）

### 主要ファイル

- `PomodoroTimerApp.swift` — アプリのエントリーポイント。SwiftDataの`ModelContainer`を`Item`スキーマで構成
- `ContentView.swift` — メインビュー。アイテムの一覧表示・追加・削除機能
- `Item.swift` — SwiftDataの`@Model`。`timestamp: Date`プロパティを持つ
