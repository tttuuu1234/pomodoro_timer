現在のブランチの変更内容からPull Requestを作成してください。

手順:
1. `git status` と `git diff main...HEAD` で変更内容を確認
2. `git log main..HEAD --oneline` でコミット履歴を確認
3. 現在のブランチがリモートにpush済みか確認し、未pushなら `git push -u origin HEAD` を実行
4. 変更内容を分析し、PRのタイトルと本文を作成
5. `gh pr create` コマンドでPRを作成
6. 作成したPRのURLを表示

PRの規則:
- タイトルは日本語で簡潔に（70文字以内）
- 本文は以下の構成にする:
  - `## 概要`: 変更の目的と内容（箇条書き1〜3点）
  - `## 変更内容`: 主な変更点の説明
  - `## テスト`: テスト方法や確認事項
- 関連Issueがあれば `Closes #番号` で紐付ける
- 末尾に `🤖 Generated with [Claude Code](https://claude.ai/code)` を付与
