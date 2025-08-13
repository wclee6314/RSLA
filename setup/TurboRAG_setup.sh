#!/usr/bin/env bash
set -Eeuo pipefail

# Get script and root directory paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_NAME="turborag"
PY_VER="3.10.12"

# Ensure we have conda in this shell
if command -v conda >/dev/null 2>&1; then
  eval "$(conda shell.bash hook)"
elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
  # Fallback for older conda
  # shellcheck disable=SC1091
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
else
  echo "Conda not found. Please install Miniconda/Anaconda first." >&2
  exit 1
fi

# Create env if it doesn't exist
if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  conda create -y -n "$ENV_NAME" "python=$PY_VER"
fi

TURBORAG_DIR="$ROOT_DIR/third_party/TurboRAG"
cd "$TURBORAG_DIR"

# Prepare a patched requirements file to resolve:
# - sentence-transformers==3.2.1 needs transformers >= 4.41,<5
REQ_IN="requirements.txt"
REQ_OUT="requirements.patched.txt"

# 1) transformers가 ==로 고정되어 있으면 >=4.41,<5 로 교체
if grep -Eq '^[[:space:]]*transformers==[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$' "$REQ_IN"; then
  sed -E 's/^[[:space:]]*transformers==[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$/transformers>=4.41,<5/' "$REQ_IN" > "$REQ_OUT"
else
  # 2) transformers 항목이 없거나 이미 범위 지정이면, 파일을 복사하고 필요시 라인 추가
  cp "$REQ_IN" "$REQ_OUT"
  if ! grep -Eq '^[[:space:]]*transformers([[:space:]]*([<>=!~]=).*)?[[:space:]]*$' "$REQ_IN"; then
    echo 'transformers>=4.41,<5' >> "$REQ_OUT"
  fi
fi

echo "[info] Using patched requirements: $REQ_OUT"
echo "------ Diff preview ------"
# 미리보기(실패해도 무시)
diff -u "$REQ_IN" "$REQ_OUT" || true
echo "--------------------------"

# Use conda run so we don't rely on 'activate'
conda run -n "$ENV_NAME" python -m pip install --upgrade pip
# 패치된 요구사항으로 설치
conda run -n "$ENV_NAME" python -m pip install -r "$REQ_OUT"
# 의존성 체크 (문제 있으면 non-zero로 종료)
conda run -n "$ENV_NAME" python -m pip check

# (선택) 확인용
conda run -n "$ENV_NAME" python -V
