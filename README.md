[![Docker Build and Push CI](https://github.com/RobWiederstein/spaceflights/actions/workflows/docker-build-push.yml/badge.svg)](https://github.com/RobWiederstein/spaceflights/actions/workflows/docker-build-push.yml)
# spaceflights

# Why this project matters

The project aims to provide a reproducible machine learning project and publishing platform in a continuous integration (CI)/ continuous development (CD) pipeline. Too many articles and research still fail the test of reproducibility.  This effort tries to address this issue by providing a complete end-to-end solution for machine learning projects, including report generation.  The software tools are open source and widely used. 

- [Docker](https://docs.docker.com/) creates a reproducible environment by packaging applications and their dependencies into portable containers.  
- [Python](https://www.python.org/) is a high-level programming language widely used for data analysis, machine learning, and general‐purpose scripting.  
- [Kedro](https://kedro.org/) provides a reproducible, modular framework for building data‐driven and machine learning pipelines. It includes built-in support for dataset versioning, configuration-driven pipelines, and a flexible plugin architecture—features that ensure your workflows are both auditable and customizable.  
- [Quarto](https://quarto.org/) is a publishing system for creating dynamic reports, websites, and presentations from code and markdown.  
- [GitHub](https://github.com/) is a cloud-based platform for hosting, version-controlling, and collaborating on code repositories.  
- [GitHub Actions](https://github.com/features/actions) automates workflows—such as testing, building, and deploying—directly from your GitHub repository.  

# Installation (via Docker)

To reproduce the project exactly (including all data pipelines and rendered docs) use the official Docker image. We have published version `v.0.1.1` to GitHub Container Registry.


1. Pull the specific release:

```bash
docker pull ghcr.io/robwiederstein/spaceflights-app:v0.1.1

# or the latest version

docker pull ghcr.io/robwiederstein/spaceflights-app:latest
```
2. Run the pipeline + render documentation

Create (or navigate to) an empty folder and run:

```bash
mkdir spaceflights-demo
cd spaceflights-demo

docker run --rm \
  -v "$(pwd)":/home/spaceflights \
  -w /home/spaceflights \
  ghcr.io/robwiederstein/spaceflights-app:v.0.1.1 \
  ./run_and_render.sh
```

This will (1) execute kedro run (building models, tables, plots, etc.), (2) invoke quarto render to build the full website into docs/_site, and (3) populate your local directory (spaceflights-demo) with all outputs.

3. Open `docs/_site/index.html` in your browser


# License
This project is licensed under the [MIT License](./LICENSE.md).