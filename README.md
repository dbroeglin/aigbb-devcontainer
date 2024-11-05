# DevContainer Template for AI work

This is a template for working on Development Containers or GitHub Codespaces with Python and Jupyter Notebooks that I use when working on AI Development projects.

Feedback and bug reports are very welcome! Please open an GitHub issue if you find something that needs fixing or improvement.

## Contents

  - `requirements.txt` for Python package dependencies. Packages in this file will be automatically installed post container creation (see https://github.com/dbroeglin/aigbb-devcontainer/blob/main/.devcontainer/devcontainer.json#35)
  - `.devcontainer/devcontainer.json` a [Development Container](https://containers.dev/) (works also as a [GitHub Codespace](https://github.com/features/codespaces)) configuration file that includes:
    - Features:
      - [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/what-is-azure-cli): `az`
      - [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview): `azd`
      - [GitHub CLI](https://cli.github.com/): `gh`
      - [Node JS](https://nodejs.org/): `node` and `npm`
      - Docker in Docker to run `docker` commands from the DevContainer
    - Extensions:
      - [GitHub Copilot](https://github.com/features/copilot)
      - several Visual Studio Code extensions for Azure
      - a YAML extension
      - [Jupyter Notebooks](https://code.visualstudio.com/docs/datascience/jupyter-notebooks)
      - [Many others](https://github.com/dbroeglin/aigbb-devcontainer/blob/main/.devcontainer/devcontainer.json#12)
  - `.gitignore` for Python
  - MIT `LICENSE`
