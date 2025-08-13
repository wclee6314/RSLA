#!/usr/bin/env bash
set -Eeuo pipefail

# 오류 위치 표시(선택)
trap 'echo "[ERROR] Failed at line $LINENO" >&2' ERR

# 스크립트 디렉토리(실행 경로와 무관)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# setup 디렉터리의 한 단계 위를 루트로 가정
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# conda 존재 확인
if ! command -v conda >/dev/null 2>&1; then
  echo "[ERROR] 'conda' 명령을 찾을 수 없습니다. Miniconda/Anaconda를 설치하고 PATH를 설정하세요." >&2
  exit 1
fi

# 비대화형 쉘에서 conda 활성화 가능하게 초기화
eval "$(conda shell.bash hook)"

ENV_NAME="transformers"
PY_VER="3.11"

# 환경이 없으면 생성(자동 승인)
if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  conda create -y -n "$ENV_NAME" "python=$PY_VER"
fi

# 환경 활성화
conda activate "$ENV_NAME"

# 빌드 도구 업그레이드
python -m pip install -U pip "setuptools>=80" wheel

# 서브모듈의 transformers를 editable로 설치
TRANSFORMERS_DIR="$ROOT_DIR/third_party/transformers"
if [[ ! -d "$TRANSFORMERS_DIR" ]]; then
  echo "[ERROR] 디렉토리를 찾을 수 없습니다: $TRANSFORMERS_DIR" >&2
  exit 1
fi

cd "$TRANSFORMERS_DIR"
pip install -e ".[torch]"
