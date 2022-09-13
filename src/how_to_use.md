# How to use

## Clone

1. Clone this repository to your repository
2. `cd docs && make init`
    1. This operation removes `.git` directory of `docs`
3. aa

## Setting up

1. Edit `your/repository/docs/mkdocs.yaml` and setup the docs
2. `make view` and check the appearance

## Build and Publish

1. `make build` and `site` directory will be generated
2. Branch `gh-pages` and delete all files except `site` directory
3. Extract `site` directory to repository root and push `gh-pages` branch
4. The page is hosted at https://pages.github.ibm.com/`username`/`reponame`
