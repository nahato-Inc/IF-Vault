#!/bin/bash
# ============================================================
# Claude Code チーム環境セットアップスクリプト
# IF-Vault / nahato-Inc
#
# 使い方: bash team/shared/claude-code-setup/install.sh
# ============================================================

set -euo pipefail

# --- カラー出力 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$1"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

# --- パス設定 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SKILLS_DIR="${CLAUDE_DIR}/skills"
SESSION_DIR="${CLAUDE_DIR}/session-env"
DEBUG_DIR="${CLAUDE_DIR}/debug"

# --- 事前チェック ---
if ! command -v claude &>/dev/null; then
  error "Claude Code がインストールされていません"
  echo "  インストール: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

echo ""
echo "========================================="
echo "  Claude Code チーム環境セットアップ"
echo "========================================="
echo ""
echo "以下をインストールします:"
echo "  - Hooks (8スクリプト): セキュリティ・効率化"
echo "  - settings.json: deny list + hooks 登録"
echo "  - Skills (19個): チーム共有スキル"
echo "  - グローバル CLAUDE.md テンプレート"
echo "  - 作業ディレクトリ (session-env, debug)"
echo ""
read -p "続行しますか？ (y/N): " confirm
if [[ "$confirm" != [yY] ]]; then
  echo "キャンセルしました"
  exit 0
fi

echo ""

# --- Step 1: ディレクトリ作成 ---
info "ディレクトリ作成..."
mkdir -p "$HOOKS_DIR" "$SKILLS_DIR" "$SESSION_DIR" "$DEBUG_DIR"
ok "ディレクトリ作成完了"

# --- Step 2: Hooks インストール ---
info "Hooks インストール (8スクリプト)..."
HOOKS_SRC="${SCRIPT_DIR}/hooks"
hooks_installed=0

for hook_file in "$HOOKS_SRC"/*.sh; do
  name=$(basename "$hook_file")
  dest="${HOOKS_DIR}/${name}"

  if [ -f "$dest" ]; then
    # 既存ファイルと差分があるかチェック
    if ! diff -q "$hook_file" "$dest" &>/dev/null; then
      warn "${name}: 既存ファイルと差分あり → バックアップして上書き"
      cp "$dest" "${dest}.bak"
    else
      ok "${name}: 最新版（スキップ）"
      continue
    fi
  fi

  cp "$hook_file" "$dest"
  chmod +x "$dest"
  ok "${name}: インストール完了"
  hooks_installed=$((hooks_installed + 1))
done

ok "Hooks: ${hooks_installed}個 新規/更新"

# --- Step 3: settings.json マージ ---
info "settings.json 設定..."
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
SETTINGS_TEMPLATE="${SCRIPT_DIR}/templates/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
  # 既存ファイルがある場合: hooks と deny をマージ
  warn "settings.json が既に存在します"

  # Python でマージ（hooks + deny を追加、既存の allow は保持）
  python3 -c "
import json, sys

with open('$SETTINGS_FILE') as f:
    existing = json.load(f)
with open('$SETTINGS_TEMPLATE') as f:
    template = json.load(f)

# deny list をマージ（重複排除）
existing_deny = set(existing.get('permissions', {}).get('deny', []))
template_deny = set(template.get('permissions', {}).get('deny', []))
merged_deny = sorted(existing_deny | template_deny)

if 'permissions' not in existing:
    existing['permissions'] = {}
existing['permissions']['deny'] = merged_deny

# hooks を上書き
existing['hooks'] = template['hooks']

# statusLine を追加
existing['statusLine'] = template['statusLine']

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write('\n')

added = template_deny - existing_deny
print(f'deny: {len(added)}個追加, hooks: 6イベント設定済み')
" 2>/dev/null

  ok "settings.json: マージ完了（既存の allow は保持）"
else
  cp "$SETTINGS_TEMPLATE" "$SETTINGS_FILE"
  ok "settings.json: 新規作成"
fi

# --- Step 4: Skills インストール ---
info "Skills インストール (19個)..."
SKILLS_SRC="${SCRIPT_DIR}/skills"
skills_installed=0
skills_skipped=0

for skill_dir in "$SKILLS_SRC"/*/; do
  name=$(basename "$skill_dir")
  dest="${SKILLS_DIR}/${name}"

  if [ -d "$dest" ] || [ -L "$dest" ]; then
    # 既存がある場合はスキップ（上書きしない）
    skills_skipped=$((skills_skipped + 1))
    continue
  fi

  cp -r "$skill_dir" "$dest"
  ok "${name}"
  skills_installed=$((skills_installed + 1))
done

ok "Skills: ${skills_installed}個 新規, ${skills_skipped}個 既存スキップ"

# --- Step 5: コミュニティスキル案内 ---
info "コミュニティスキル (17個) は手動インストールが必要です"
echo ""
echo "  Claude Code を起動して以下を実行:"
echo "    /find-skills"
echo ""
echo "  推奨スキル:"
echo "    - baseline-ui, deep-research, docx, ffmpeg, find-skills"
echo "    - finishing-a-development-branch, mermaid-visualizer"
echo "    - pdf, pptx, security-review, systematic-debugging"
echo "    - supabase-postgres-best-practices, typescript-best-practices"
echo "    - using-git-worktrees, ux-psychology"
echo "    - vercel-react-best-practices, xlsx"
echo ""

# --- Step 6: グローバル CLAUDE.md ---
CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
  warn "CLAUDE.md が既に存在します（スキップ）"
  echo "  テンプレートは ${SCRIPT_DIR}/templates/CLAUDE.md にあります"
  echo "  必要に応じて手動でカスタマイズしてください"
else
  cp "${SCRIPT_DIR}/templates/CLAUDE.md" "$CLAUDE_MD"
  ok "CLAUDE.md: テンプレートをインストール"
  echo "  ${CLAUDE_MD} を自分の好みに合わせてカスタマイズしてください"
fi

# --- Step 7: Context7 MCP ---
info "Context7 MCP (リアルタイムドキュメント参照)..."
if command -v claude &>/dev/null; then
  claude mcp add context7 -- npx -y @upstash/context7-mcp@latest 2>/dev/null && \
    ok "Context7 MCP: 追加完了" || \
    warn "Context7 MCP: 追加に失敗（手動で追加してください）"
fi

# --- 完了 ---
echo ""
echo "========================================="
echo "  セットアップ完了!"
echo "========================================="
echo ""
echo "インストール内容:"
echo "  ~/.claude/hooks/        ... 8スクリプト"
echo "  ~/.claude/settings.json ... deny list + hooks"
echo "  ~/.claude/skills/       ... 19 チームスキル"
echo "  ~/.claude/session-env/  ... セッション管理用"
echo "  ~/.claude/debug/        ... デバッグログ用"
echo ""
echo "次のステップ:"
echo "  1. ~/.claude/CLAUDE.md を自分の好みにカスタマイズ"
echo "  2. Claude Code を再起動して設定を反映"
echo "  3. /find-skills でコミュニティスキルを追加"
echo ""
