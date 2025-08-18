#!/usr/bin/env bash
# add-submodule.sh (fixed)
# Interactively add a git submodule and set ignore=dirty (or all)
# - Uses --name to fix the submodule section name
# - Sets ignore without over-escaping (no \")
# - Cleans up any rogue sections named with literal quotes

set -euo pipefail

die() { echo "❌ $*" >&2; exit 1; }

# trim leading ./ and trailing /
normalize_path() {
  local p="$1"
  while [[ "$p" == ./* ]]; do p="${p:2}"; done
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

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "여기서는 git 리포를 찾을 수 없어요. 리포 루트에서 실행하세요."

GIT_URL="$(prompt '서브모듈 Git URL 입력')"
[[ -n "$GIT_URL" ]] || die "Git URL은 비어 있을 수 없습니다."

RAW_PATH="$(prompt '클론할 경로(path) 입력 (예: third_party/TurboRAG)')"
[[ -n "$RAW_PATH" ]] || die "경로는 비어 있을 수 없습니다."
SUB_PATH="$(normalize_path "$RAW_PATH")"

# 경로에 쌍따옴표는 허용하지 않음 (문제의 근원 차단)
if [[ "$SUB_PATH" == *\"* ]]; then
  die "경로에 쌍따옴표(\")를 포함할 수 없습니다: $SUB_PATH"
fi

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

# 1) add submodule (섹션명을 path와 동일하게 고정)
git submodule add --name "$SUB_PATH" "$GIT_URL" "$SUB_PATH"

# 2) .gitmodules 에 ignore 추가 (불필요한 \\" 제거! → 정석 표기)
git config -f .gitmodules submodule."$SUB_PATH".ignore "$IGNORE_MODE"
git add .gitmodules

# 3) 로컬 .git/config 에도 동일 설정
git config submodule."$SUB_PATH".ignore "$IGNORE_MODE"

# 4) 과거 실수로 생긴 '따옴표 포함 섹션명' 정리 (있으면 제거)
#    섹션명이 실제로 "third_party/xxx" 를 포함하는 경우 → 키상으로는 \"...\" 로 표기됨
BADSEC=submodule.\""$SUB_PATH"\"
if git config -f .gitmodules --name-only --get-regexp "^$BADSEC\\." >/dev/null 2>&1; then
  git config -f .gitmodules --remove-section "$BADSEC" || true
  git add .gitmodules
fi
if git config --name-only --get-regexp "^$BADSEC\\." >/dev/null 2>&1; then
  git config --remove-section "$BADSEC" || true
fi

# 5) 검증: 올바른 섹션에 ignore 가 설정되었는지 확인
git config -f .gitmodules --get "submodule.$SUB_PATH.ignore" >/dev/null \
  || die ".gitmodules 에 ignore 설정이 적용되지 않았습니다."
git config --get "submodule.$SUB_PATH.ignore" >/dev/null \
  || die ".git/config 에 ignore 설정이 적용되지 않았습니다."

# 6) 커밋
git commit -m "$COMMIT_MSG"

# 7) 결과 표시 & 동기화 안내
echo
echo "✅ 완료! 현재 ignore 설정:"
git config -f .gitmodules --get-regexp '^submodule\..*\.ignore' || true
git config --get-regexp '^submodule\..*\.ignore' || true

echo
echo "참고) 다른 클론에서 반영하려면:"
echo "  git submodule init"
echo "  git submodule sync --recursive"
