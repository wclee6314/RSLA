# repository download
```bash
git clone https://github.com/wclee6314/RSLA.git
```
```bash
git submodule update --init --recursive third_party/openvla
```
```bash
git submodule update --init --recursive third_party/LIBERO
```

# env setup (conda: openvla)
```bash
bash ./setup/openvla_setup.sh
```

# download fine-tuned OpenVLA model via LoRA (r=32) on four LIBERO task suites
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

# deploy (evaluation)
### libero-spatial
```bash
OPENVLA_PATH="/home/jovyan/workspace/RSLA/third_party/openvla"
cd OPENVLA_PATH
python experiments/robot/libero/run_libero_eval.py   --model_family openvla   --pretrained_checkpoint /home/jovyan/model-wclee/openvla/openvla-7b-finetuned-libero-spatial   --task_suite_name libero_spatial   --center_crop True --use_wandb True --wandb_project openvla_eval --wandb_entity wclee-korea-advanced-institute-of-science-and-technology
```

### libero_object
```bash
OPENVLA_PATH="/home/jovyan/workspace/RSLA/third_party/openvla"
cd OPENVLA_PATH
python experiments/robot/libero/run_libero_eval.py   --model_family openvla   --pretrained_checkpoint /home/jovyan/model-wclee/openvla/openvla-7b-finetuned-libero-object   --task_suite_name libero_object   --center_crop True --use_wandb True --wandb_project openvla_eval --wandb_entity wclee-korea-advanced-institute-of-science-and-technology
```

### libero_goal
```bash
OPENVLA_PATH="/home/jovyan/workspace/RSLA/third_party/openvla"
cd OPENVLA_PATH
python experiments/robot/libero/run_libero_eval.py   --model_family openvla   --pretrained_checkpoint /home/jovyan/model-wclee/openvla/openvla-7b-finetuned-libero-goal   --task_suite_name libero_goal   --center_crop True --use_wandb True --wandb_project openvla_eval --wandb_entity wclee-korea-advanced-institute-of-science-and-technology
```

### libero_10
```bash
OPENVLA_PATH="/home/jovyan/workspace/RSLA/third_party/openvla"
cd OPENVLA_PATH
python experiments/robot/libero/run_libero_eval.py   --model_family openvla   --pretrained_checkpoint /home/jovyan/model-wclee/openvla/openvla-7b-finetuned-libero-10   --task_suite_name libero_10   --center_crop True --use_wandb True --wandb_project openvla_eval --wandb_entity wclee-korea-advanced-institute-of-science-and-technology
```