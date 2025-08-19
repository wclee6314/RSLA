# 
```bash
git clone https://github.com/wclee6314/RSLA.git
```
```bash
git submodule update --init --recursive third_party
```

# env setup (conda: openvla)
```bash
bash ./setup/openvla_setup.sh
```

# fine-tuned OpenVLA model via LoRA (r=32) on four LIBERO task suites
### libero-spatial
```bash
HF_MODEL="openvla/openvla-7b-finetuned-libero-spatial"
LOCAL_DIR="/home/jovyan/model-wclee/${HF_MODEL#*/}"  
mkdir -p "$LOCAL_DIR"
hf download "$HF_MODEL" --local-dir "$LOCAL_DIR"
```

### libero-object
```bash
# 1) libero-object
HF_MODEL="openvla/openvla-7b-finetuned-libero-object"
LOCAL_DIR="/home/jovyan/model-wclee/${HF_MODEL#*/}"
mkdir -p "$LOCAL_DIR"
hf download "$HF_MODEL" --local-dir "$LOCAL_DIR"
```

### libero-goal
```bash
# 2) libero-goal
HF_MODEL="openvla/openvla-7b-finetuned-libero-goal"
LOCAL_DIR="/home/jovyan/model-wclee/${HF_MODEL#*/}"
mkdir -p "$LOCAL_DIR"
hf download "$HF_MODEL" --local-dir "$LOCAL_DIR"
```

### libero-10
```bash
# 3) libero-10
HF_MODEL="openvla/openvla-7b-finetuned-libero-10"
LOCAL_DIR="/home/jovyan/model-wclee/${HF_MODEL#*/}"
mkdir -p "$LOCAL_DIR"
hf download "$HF_MODEL" --local-dir "$LOCAL_DIR"
```

# 