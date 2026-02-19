# Claude Code チーム環境セットアップ

nahato-Inc チーム共通の Claude Code 環境設定。

## クイックスタート

```bash
# IF-Vault リポジトリのルートから実行
bash team/shared/claude-code-setup/install.sh
```

確認プロンプトが出るので `y` で続行。既存ファイルは上書きしない（差分がある hooks のみバックアップ＆更新）。

## 何がインストールされるか

### Hooks（8スクリプト）

| スクリプト | イベント | 機能 |
|-----------|---------|------|
| block-sensitive-read.sh | PreToolUse (Read) | .env/.pem/.key 等の読み取りをブロック |
| token-guardian-warn.sh | PreToolUse (Read) | 6KB超ファイルの読み取りで警告 |
| session-compact-restore.sh | PreCompact | コンテキスト圧縮前に作業状態を保存 |
| security-post-edit.sh | PostToolUse (Edit/Write) | 編集後に機密情報パターンを検出 |
| session-stop-summary.sh | Stop | 未コミット変更の通知 + settings.local.json 自動クリーン |
| tool-failure-logger.sh | PostToolUseFailure | ツール連続失敗を検出・記録 |
| notification.sh | Notification | macOS 通知で確認要求を即座に察知 |
| statusline.sh | StatusLine | git branch + 変更数 + 作業ディレクトリを常時表示 |

### Deny List（7エントリ）

settings.json に登録される破壊的コマンドのブロックリスト:

- `rm -rf` / `git push --force` / `git push -f`
- `git reset --hard` / `git clean -fd`
- `git checkout .` / `git restore .`

### Skills（19個・チーム自作）

フロントエンド、バックエンド、品質管理、DevOps 等のスキル。`~/.claude/skills/` にインストールされる。

一覧: ci-cd-deployment, claude-env-optimizer, context-economy, dashboard-data-viz, design-token-system, docker-expert, error-handling-logging, line-bot-dev, micro-interaction-patterns, mobile-first-responsive, natural-japanese-writing, nextjs-app-router-patterns, obsidian-power-user, react-component-patterns, skill-forge, supabase-auth-patterns, tailwind-design-system, testing-strategy, web-design-guidelines

### コミュニティスキル（17個・手動インストール）

`/find-skills` で検索してインストール:

baseline-ui, deep-research, docx, ffmpeg, find-skills, finishing-a-development-branch, mermaid-visualizer, pdf, pptx, security-review, supabase-postgres-best-practices, systematic-debugging, typescript-best-practices, using-git-worktrees, ux-psychology, vercel-react-best-practices, xlsx

### CLAUDE.md テンプレート

`~/.claude/CLAUDE.md` が存在しない場合のみインストール。チーム共通のベースルール（日本語応対、セキュリティ、Git運用）を含む。**インストール後に自分の好みにカスタマイズすること。**

## セットアップ後にやること

1. `~/.claude/CLAUDE.md` を開いて、自分の口調・スタイルを追加
2. Claude Code を再起動（`claude` コマンドを再実行）
3. `/find-skills` でコミュニティスキルをインストール

## ディレクトリ構成

```
~/.claude/
├── CLAUDE.md                  # 個人設定（テンプレートから作成）
├── settings.json              # hooks + deny list
├── hooks/                     # 8スクリプト
├── skills/                    # 36スキル（自作19 + コミュニティ17）
├── session-env/               # セッション状態保存
└── debug/                     # デバッグログ
```

## 更新方法

git pull 後に再度 `install.sh` を実行すれば、差分のある hooks のみ更新される。既存の skills や CLAUDE.md は上書きされない。
