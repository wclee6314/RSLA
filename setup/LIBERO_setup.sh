#!/usr/bin/env bash
set -euo pipefail

# ====== 이 두 값을 당신의 환경에 맞게 수정하세요 ======
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBERO_DIR="$ROOT_DIR/third_party/LIBERO"
CONDA_ENV="libero"                      # 생성/사용할 conda 환경 이름
# =====================================================

# 1) conda 사용 준비
if ! command -v conda >/dev/null 2>&1; then
  for p in "$HOME/miniconda3/etc/profile.d/conda.sh" \
           "$HOME/anaconda3/etc/profile.d/conda.sh" \
           "/opt/conda/etc/profile.d/conda.sh"
  do
    if [ -f "$p" ]; then
      # shellcheck disable=SC1090
      . "$p"
      break
    fi
  done
fi

if ! command -v conda >/dev/null 2>&1; then
  echo "ERROR: conda를 찾을 수 없습니다. Miniconda/Anaconda 설치 후 다시 실행하세요."
  exit 1
fi

# 2) 환경 생성(이미 있으면 건너뜀)
if conda env list | awk '/^\S/ {print $1}' | grep -qx "$CONDA_ENV"; then
  echo "[info] conda env '$CONDA_ENV'가 이미 존재합니다. 생성을 건너뜁니다."
else
  conda create -y -n "$CONDA_ENV" python=3.8.13
fi

# 3) 환경 활성화 (hook 로드 필요)
# shellcheck disable=SC1090
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$CONDA_ENV"

# 4) 로컬 LIBERO 디렉토리로 이동
if [ ! -d "$LIBERO_DIR" ]; then
  echo "ERROR: LIBERO_DIR이 유효한 디렉토리가 아닙니다: $LIBERO_DIR"
  exit 1
fi
cd "$LIBERO_DIR"

# 5) Python/패키지 설치
python -m pip install --upgrade pip
if [ ! -f "requirements.txt" ]; then
  echo "ERROR: requirements.txt가 ${LIBERO_DIR}에 없습니다."
  exit 1
fi
python -m pip install -r requirements.txt

# 6) PyTorch(CUDA 11.3) 설치
python -m pip install \
  torch==1.11.0+cu113 \
  torchvision==0.12.0+cu113 \
  torchaudio==0.11.0 \
  --extra-index-url https://download.pytorch.org/whl/cu113

# 7) LIBERO 패키지 설치 (개발 모드)
python -m pip install -e .

echo
echo "[done] '$CONDA_ENV' 환경에 LIBERO 설치 완료 ✅"
python -V
pip show torch | sed -n '1,6p'
