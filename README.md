# RSLA

## Included Packages

The RSLA package includes the following third-party dependencies:

* [Hugging Face Transformers](https://github.com/huggingface/transformers) - State-of-the-art Natural Language Processing library

## Clone

To clone this repository with all submodules, run:

```bash
git clone --recursive https://github.com/wclee6314/RSLA.git
```

Or if you've already cloned the repository without `--recursive`, run:

```bash
git submodule update --init --recursive
```

## Setup

Follow these steps to set up the environment and dependencies:

1. **Install Conda** (if not already installed):
   ```bash
   ./setup/miniconda_setup.sh
   ```

2. **Set up Transformers**:
   After conda is installed and available in your environment, run:
   ```bash
   ./setup/transformers_setup.sh
   ```
   This will create a conda environment named 'transformers' and install the Hugging Face Transformers library from the submodule.
