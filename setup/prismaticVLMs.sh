#!/usr/bin/env bash
set -Eeuo pipefail

# =========================
# Path setup
# =========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRISM_DIR="$ROOT_DIR/third_party/prismatic-vlms"

# =========================
# Config (override via env or flags)
# =========================
ENV_NAME="${ENV_NAME:-prismatic-vlms}"
PY_VER="${PY_VER:-3.10.13}"

# Version bundle: 2024-03-24 or 2024-02-16
PROFILE="${PROFILE:-2024-03-24}"

# CUDA flavor for PyTorch index: cpu | cu118 | cu121 | cu124
CUDA_FLAVOR="${CUDA_FLAVOR:-cu121}"

# Install Flash-Attention? (1=yes, 0=no)
INSTALL_FLASH_ATTN="${INSTALL_FLASH_ATTN:-1}"

# =========================
# Helpers
# =========================
log(){ echo -e "\033[1;34m[info]\033[0m $*"; }
warn(){ echo -e "\033[1;33m[warn]\033[0m $*" >&2; }
err(){ echo -e "\033[1;31m[err]\033[0m  $*" >&2; }

usage() {
  cat <<EOF
Usage: $0 [--env NAME] [--py VER] [--profile 2024-03-24|2024-02-16] [--cuda cpu|cu118|cu121|cu124] [--no-flash]

Examples:
  $0 --env prismatic --py 3.10.13 --profile 2024-03-24 --cuda cu121
  PROFILE=2024-02-16 CUDA_FLAVOR=cpu $0
EOF
}

# Parse flags (simple)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENV_NAME="$2"; shift 2 ;;
    --py) PY_VER="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --cuda) CUDA_FLAVOR="$2"; shift 2 ;;
    --no-flash) INSTALL_FLASH_ATTN=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

# =========================
# Version bundles
# =========================
case "$PROFILE" in
  2024-03-24)
    TORCH_VER="2.2.0"
    TV_VER="0.17.0"
    TRANSFORMERS_VER="4.38.1"
    FLASH_ATTN_VER="2.5.5"
    ;;
  2024-02-16)
    TORCH_VER="2.1.0"
    TV_VER="0.16.0"
    TRANSFORMERS_VER="4.34.1"
    FLASH_ATTN_VER="2.3.3"
    ;;
  *)
    err "Unknown PROFILE: $PROFILE (allowed: 2024-03-24 | 2024-02-16)"; exit 1 ;;
esac

# =========================
# Torch index by CUDA flavor
# =========================
case "$CUDA_FLAVOR" in
  cpu)  TORCH_INDEX_URL="https://download.pytorch.org/whl/cpu" ;;
  cu118) TORCH_INDEX_URL="https://download.pytorch.org/whl/cu118" ;;
  cu121) TORCH_INDEX_URL="https://download.pytorch.org/whl/cu121" ;;
  cu124) TORCH_INDEX_URL="https://download.pytorch.org/whl/cu124" ;;
  *) err "Unknown CUDA_FLAVOR: $CUDA_FLAVOR (allowed: cpu|cu118|cu121|cu124)"; exit 1 ;;
esac

# =========================
# Pre checks
# =========================
if [[ ! -d "$PRISM_DIR" ]]; then
  err "Repo not found at: $PRISM_DIR
현재 프로젝트 루트($ROOT_DIR)/third_party/prismatic-vlms 경로를 확인하세요."
  exit 1
fi

# Ensure conda
if command -v conda >/dev/null 2>&1; then
  eval "$(conda shell.bash hook)"
elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
  # shellcheck disable=SC1091
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
else
  err "Conda not found. Miniconda/Anaconda를 먼저 설치하세요."
  exit 1
fi

# Flash-Attention 지원 불가 환경 감지 (macOS/Windows 또는 GPU 없음)
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
if [[ "$OS" == "darwin" || "$OS" == "mingw"* || "$OS" == "msys"* || "$OS" == "cygwin"* ]]; then
  warn "이 OS에서는 Flash-Attention 설치가 제한될 수 있습니다. 건너뜁니다."
  INSTALL_FLASH_ATTN=0
fi
if ! command -v nvidia-smi >/dev/null 2>&1; then
  warn "NVIDIA GPU가 감지되지 않았습니다. Flash-Attention 설치를 건너뜁니다."
  INSTALL_FLASH_ATTN=0
fi

# =========================
# Create env if needed
# =========================
if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  log "Creating conda env '$ENV_NAME' (python=$PY_VER)"
  conda create -y -n "$ENV_NAME" "python=$PY_VER"
else
  log "Conda env '$ENV_NAME' already exists. Continuing."
fi

# =========================
# Core installs
# =========================
log "Upgrading pip/setuptools/wheel"
conda run -n "$ENV_NAME" python -m pip install --upgrade pip setuptools wheel

log "Installing PyTorch $TORCH_VER / Torchvision $TV_VER  [$CUDA_FLAVOR]"
conda run -n "$ENV_NAME" python -m pip install \
  --index-url "$TORCH_INDEX_URL" \
  "torch==${TORCH_VER}" "torchvision==${TV_VER}"

log "Installing Transformers $TRANSFORMERS_VER"
conda run -n "$ENV_NAME" python -m pip install "transformers==${TRANSFORMERS_VER}"

# Build helpers (for flash-attn)
log "Installing packaging & ninja"
conda run -n "$ENV_NAME" python -m pip install packaging ninja
set +e
conda run -n "$ENV_NAME" bash -lc 'ninja --version >/dev/null 2>&1'
NINJA_RC=$?
set -e
if [[ $NINJA_RC -ne 0 ]]; then
  warn "ninja 실행 확인 실패. build-essential(또는 Xcode CLT)이 필요할 수 있습니다."
fi

# =========================
# Flash-Attention (optional)
# =========================
if [[ "$INSTALL_FLASH_ATTN" == "1" ]]; then
  log "Installing Flash-Attention $FLASH_ATTN_VER (no-build-isolation)"
  conda run -n "$ENV_NAME" python -m pip cache remove flash_attn || true
  conda run -n "$ENV_NAME" python -m pip install "flash-attn==${FLASH_ATTN_VER}" --no-build-isolation
else
  warn "Flash-Attention 설치를 건너뜁니다. (필요 시 --no-flash 옵션 제거)"
fi

# =========================
# Editable install of prismatic-vlms
# =========================
log "Editable install: $PRISM_DIR"
conda run -n "$ENV_NAME" bash -lc "cd \"$PRISM_DIR\" && python -m pip install -e ."

# =========================
# Sanity checks
# =========================
log "pip check"
conda run -n "$ENV_NAME" python -m pip check || warn "pip check에서 경고/에러 발생. 의존성 충돌을 확인하세요."

log "Version summary"
conda run -n "$ENV_NAME" python - <<'PY'
import sys, importlib
print("Python       :", sys.version.split()[0])
try:
    import torch; print("Torch        :", torch.__version__)
except Exception as e:
    print("Torch        : <not found>", e)
try:
    import torchvision; print("Torchvision  :", torchvision.__version__)
except Exception as e:
    print("Torchvision  : <not found>", e)
try:
    import transformers; print("Transformers :", transformers.__version__)
except Exception as e:
    print("Transformers : <not found>", e)
try:
    fa = importlib.import_module("flash_attn")
    print("Flash-Attn   :", getattr(fa, "__version__", "installed"))
except Exception as e:
    print("Flash-Attn   : <not installed>", e)
PY

log "Done. 사용 전:  conda activate $ENV_NAME"
