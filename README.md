# RSLA (Robot, Sensor, Language, Action)

## Clone

To clone this repository with all submodules, run:

```bash
git clone --recursive https://github.com/wclee6314/RSLA.git
```

Or if you've already cloned the repository without `--recursive`, run:

```bash
git submodule update --init --recursive
```

Or if you want to clone specific repository, run:

```bash
git submodule update --init --recursive <path_to_repo(ex., third_party/TurboRAG)>
```

To add new submodule, run:
```bash
bash add_submodule.sh
```

## Included 3rd Party Packages

The RSLA package includes the following third-party dependencies:

* [Hugging Face Transformers](https://github.com/huggingface/transformers) - State-of-the-art Natural Language Processing library
* [TurboRAG](https://github.com/turborag/TurboRAG) - High-performance Retrieval-Augmented Generation framework
* [Prismatic VLMs](https://github.com/TRI-ML/prismatic-vlms) - Vision-Language Models


## Setup

Follow these steps to set up the environment:

1. **Install Conda** (if not already installed):
   ```bash
   bash ./setup/miniconda_setup.sh
   ```

2. **Set up Dependencies**:
   After conda is installed and available in your environment, run:
   #### Transformers (conda env: transformers)
   ```bash
   bash ./setup/transformers_setup.sh
   ```
   
   #### TurboRAG (conda env: turborag)
   ```bash
   bash ./setup/TurboRAG_setup.sh
   ```

   #### Prismatic VLMs (conda env: prismatic)
   ```bash
   bash ./setup/prismaticVLMs.sh
   ```

# Contributors
- woo-cheol lee (wclee@dnotitia.com)
