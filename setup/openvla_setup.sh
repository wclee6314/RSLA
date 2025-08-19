#!/usr/bin/env bash
# OpenVLA setup (pinned versions)
# - Python 3.10
# - PyTorch + pytorch-cuda=12.4 (GPU가 없으면 CPU 전환)
# - flash-attn==2.5.5

# set -euxo pipefail
set -euo pipefail

# ================= 설정 (고정) =================
ENV_NAME="openvla"             # 고정
PY_VERSION="3.10"              # 고정
TORCH_CUDA_VERSION="12.4"      # 고정 (PyTorch 메타패키지)
INSTALL_FLASH_ATTN="${INSTALL_FLASH_ATTN:-1}"  # 1=설치, 0=건너뛰기

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENVLA_DIR="$ROOT_DIR/third_party/openvla"   # 변경: OPENVLA_DIR로 사용
LIBERO_DIR="$ROOT_DIR/third_party/LIBERO"

log()   { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

# 현재 스크립트가 source로 실행됐는지 감지
IS_SOURCED=0
# shellcheck disable=SC2128
if [ -n "${ZSH_EVAL_CONTEXT:-}" ] && [[ "$ZSH_EVAL_CONTEXT" == *:file ]]; then
  IS_SOURCED=1
elif [ -n "${BASH_SOURCE:-}" ] && [ "${BASH_SOURCE[0]}" != "$0" ]; then
  IS_SOURCED=1
fi

# ===== conda 로드 =====
ensure_conda() {
  if ! command -v conda >/dev/null 2>&1; then
    for CAND in \
      "$HOME/miniconda3/etc/profile.d/conda.sh" \
      "$HOME/anaconda3/etc/profile.d/conda.sh"
    do
      [ -f "$CAND" ] && { # shellcheck disable=SC1090
        source "$CAND"; break;
      }
    done
  fi

  if command -v conda >/dev/null 2>&1; then
    BASE="$(conda info --base 2>/dev/null || true)"
    if [ -n "${BASE:-}" ] && [ -f "$BASE/etc/profile.d/conda.sh" ]; then
      # shellcheck disable=SC1090
      source "$BASE/etc/profile.d/conda.sh"
    fi
  elif [ -n "${CONDA_EXE:-}" ] ; then
    HOOK="$( "$CONDA_EXE" shell.bash hook 2>/dev/null || true )"
    [ -n "$HOOK" ] && eval "$HOOK"
  fi

  command -v conda >/dev/null 2>&1 || { error "conda를 찾을 수 없습니다. Miniconda/Anaconda를 먼저 설치하세요."; exit 1; }
}

log "Conda 확인 및 초기화"
ensure_conda

# mamba 있으면 사용
PKG_CMD="conda"
if command -v mamba >/dev/null 2>&1; then
  PKG_CMD="mamba"
  log "mamba 감지: 패키지 설치에 mamba 사용"
fi

# ===== 환경 생성/활성화 =====
if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  log "콘다 환경 '$ENV_NAME' 이미 존재"
else
  log "콘다 환경 '$ENV_NAME' 생성 (Python ${PY_VERSION})"
  "$PKG_CMD" create -n "$ENV_NAME" "python=${PY_VERSION}" -y
fi

log "환경 활성화: $ENV_NAME"
conda activate "$ENV_NAME"

# ===== PyTorch 설치 (GPU 감지 시 CUDA 12.4, 아니면 CPU 전용) =====
USE_CUDA=0
if command -v nvidia-smi >/dev/null 2>&1 && [ "$(uname -s)" = "Linux" ]; then
  USE_CUDA=1
fi

if [ "$USE_CUDA" -eq 1 ]; then
  log "NVIDIA GPU 감지 → PyTorch(CUDA ${TORCH_CUDA_VERSION}) 설치 (고정)"
  if ! "$PKG_CMD" install pytorch torchvision torchaudio "pytorch-cuda=${TORCH_CUDA_VERSION}" -c pytorch -c nvidia -y; then
    warn "pytorch-cuda=${TORCH_CUDA_VERSION} 설치 실패 → CPU 전용으로 대체"
    "$PKG_CMD" install pytorch torchvision torchaudio cpuonly -c pytorch -y
  fi
else
  log "GPU 미감지/비리눅스 → PyTorch(CPU 전용) 설치"
  "$PKG_CMD" install pytorch torchvision torchaudio cpuonly -c pytorch -y
fi

# ===== OpenVLA 설치 =====
log "리포지토리로 이동: $OPENVLA_DIR"
cd "$OPENVLA_DIR" 2>/dev/null || { error "경로를 찾을 수 없습니다: $OPENVLA_DIR  (third_party/openvla 가 있어야 합니다)"; exit 1; }

log "pip 업그레이드 및 editable 설치"
python -m pip install --upgrade pip
python -m pip install -e .

# # ===== LIBERO 설치 =====
# log "LIBERO 설치 준비: $LIBERO_DIR"
# if [ -d "$LIBERO_DIR" ]; then
#   log "리포지토리로 이동: $LIBERO_DIR"
#   cd "$LIBERO_DIR" 2>/dev/null || { error "경로 이동 실패: $LIBERO_DIR"; exit 1; }

#   log "LIBERO를 editable 모드로 설치"
#   python -m pip install -e .
# else
#   error "경로를 찾을 수 없습니다: $LIBERO_DIR  (third_party/LIBERO 가 있어야 합니다)"
#   exit 1
# fi

# # ===== LIBERO 추가 requirements 설치 =====
# REQ_FILE="$OPENVLA_DIR/experiments/robot/libero/libero_requirements.txt"
# log "OpenVLA 디렉터리로 복귀: $OPENVLA_DIR"
# cd "$OPENVLA_DIR" 2>/dev/null || { error "경로를 찾을 수 없습니다: $OPENVLA_DIR"; exit 1; }

# if [ -f "$REQ_FILE" ]; then
#   log "LIBERO 관련 requirements 설치: $REQ_FILE"
#   python -m pip install -r "$REQ_FILE"
# else
#   error "요구사항 파일을 찾을 수 없습니다: $REQ_FILE"
#   exit 1
# fi

# ===== FlashAttention2 (고정: 2.5.5, 선택) =====
if [ "$INSTALL_FLASH_ATTN" -eq 1 ] && [ "$USE_CUDA" -eq 1 ]; then
  log "FlashAttention2(2.5.5) 설치 시도 (GPU & 리눅스 환경)"
  python -m pip install packaging ninja
  if command -v ninja >/dev/null 2>&1; then
    if ninja --version >/dev/null 2>&1; then
      log "Ninja 확인 완료"
    else
      warn "Ninja 확인 실패(버전 출력 실패)"
    fi
  else
    warn "ninja 명령이 PATH에 없습니다. (pip로 설치했더라도 새 쉘에서만 인식될 수 있음)"
  fi
  if ! python -m pip install "flash-attn==2.5.5" --no-build-isolation; then
    warn "FlashAttention2 설치 실패. 필요 시:
  - pip cache remove flash_attn
  - CUDA/컴파일러 호환성 확인
  - 공식 문서의 Troubleshooting 참고"
  fi
else
  [ "$INSTALL_FLASH_ATTN" -eq 0 ] && warn "요청에 따라 FlashAttention2 설치를 건너뜁니다."
  [ "$USE_CUDA" -eq 0 ] && warn "GPU/리눅스 환경이 아니므로 FlashAttention2 설치를 건너뜁니다."
fi

log "설치 완료! 환경 이름: $ENV_NAME"

if [ "$IS_SOURCED" -eq 1 ]; then
  log "현재 쉘에서 '$ENV_NAME'가 활성화된 상태입니다."
else
  cat <<EOF
============================================================
환경 활성화 방법:

  conda activate $ENV_NAME

※ 설치 후에도 자동 활성화를 원하면 아래처럼 실행하세요:
  source ./$(basename "$0")
============================================================
EOF
fi
