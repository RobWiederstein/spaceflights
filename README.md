![CI/CD](https://github.com/RobWiederstein/spaceflights/actions/workflows/ci.yml/badge.svg)

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

Rather than installing dependencies locally, you can pull the prebuilt Docker image from the GitHub Container Registry and run everything inside the container:

Pull the v0.1.0 image

```bash
docker pull ghcr.io/robwiederstein/spaceflights-app:v0.1.0
```

To run the Kedro pipeline from the project root (where your spaceflights folder lives), execute:

```bash
docker run --rm \
  -v "$(pwd)":/home/spaceflights \
  -w /home/spaceflights \
  ghcr.io/robwiederstein/spaceflights-app:v0.1.0 \
  kedro run
```

This command: mounts your local project directory ($(pwd)) into `/home/spaceflights` inside the container, sets the working directory to `/home/spaceflights`, runs `kedro run` using the image’s pre-installed Python, Kedro, and other dependencies.

To build the Quarto site (e.g., `docs/index.qmd`), run:

```bash
docker run --rm \
  -v "$(pwd)":/home/spaceflights \
  -w /home/spaceflights \
  ghcr.io/robwiederstein/spaceflights-app:v0.1.0 \
  ./run_and_render.sh
```