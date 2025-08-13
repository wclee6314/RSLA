#!/usr/bin/env bash
# add-submodule.sh
# Interactively add a git submodule and set ignore=dirty (or all)

set -euo pipefail

# --- helpers ---------------------------------------------------------------
die() { echo "❌ $*" >&2; exit 1; }

# trim leading ./ and trailing /
normalize_path() {
  local p="$1"
  # strip leading ./ (repeat)
  while [[ "$p" == ./* ]]; do p="${p:2}"; done
  # strip trailing /
  p="${p%/}"
  printf '%s' "$p"
}

prompt() {
  local msg="$1" default="${2:-}"
  local ans
  if [[ -n "$default" ]]; then
    read -rp "$msg [$default]: " ans
    printf '%s' "${ans:-$default}"
  else
    read -rp "$msg: " ans
    printf '%s' "$ans"
  fi
}

# --- prechecks -------------------------------------------------------------
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "여기서는 git 리포를 찾을 수 없어요. 리포 루트에서 실행하세요."

# --- input -----------------------------------------------------------------
GIT_URL="$(prompt '서브모듈 Git URL 입력')"
[[ -n "$GIT_URL" ]] || die "Git URL은 비어 있을 수 없습니다."

RAW_PATH="$(prompt '클론할 경로(path) 입력 (예: third_party/TurboRAG)')"
[[ -n "$RAW_PATH" ]] || die "경로는 비어 있을 수 없습니다."
SUB_PATH="$(normalize_path "$RAW_PATH")"

IGNORE_MODE="$(prompt 'ignore 모드 선택 (dirty/all)' 'dirty')"
case "$IGNORE_MODE" in
  dirty|all) ;;
  *) die "IGNORE 모드는 dirty 또는 all 만 가능합니다." ;;
esac

DEFAULT_MSG="Add submodule: ${SUB_PATH} (ignore ${IGNORE_MODE})"
COMMIT_MSG="$(prompt '커밋 메시지 입력' "$DEFAULT_MSG")"

echo
echo "▶ 준비 내용 확인"
echo "   URL   : $GIT_URL"
echo "   PATH  : $SUB_PATH"
echo "   IGNORE: $IGNORE_MODE"
echo "   COMMIT: $COMMIT_MSG"
read -rp "진행할까요? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
[[ "$CONFIRM" =~ ^[Yy]$ ]] || die "사용자 취소"

# --- main ------------------------------------------------------------------
# 1) add submodule
git submodule add -f "$GIT_URL" "$SUB_PATH"

# 2) set ignore in .gitmodules + stage it
#    Need quotes around subsection -> submodule."$SUB_PATH".ignore
#    Escape any double-quotes in path just in case (rare)
NAME_ESCAPED="$(printf '%s' "$SUB_PATH" | sed 's/"/\\"/g')"

git config -f .gitmodules "submodule.\"$NAME_ESCAPED\".ignore" "$IGNORE_MODE"
git add .gitmodules

# 3) set ignore in local config as well
git config "submodule.\"$NAME_ESCAPED\".ignore" "$IGNORE_MODE"

# 4) commit
git commit -m "$COMMIT_MSG"

# 5) show effective config lines
echo
echo "✅ 완료! 현재 ignore 설정:"
git config -f .gitmodules --get-regexp '^submodule\..*\.ignore' || true
git config --get-regexp '^submodule\..*\.ignore' || true

echo
echo "참고) 서브모듈 설정을 다른 클론에서 반영하려면:"
echo "  git submodule init"
echo "  git submodule sync --recursive"
