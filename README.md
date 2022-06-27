# devtool-ui-tester

This repository is a provides a simple way to ensure compatibilty of React projects accross different Node environments.

## Installation

The compatibily check is run against the repositories in the `repositories.json` file. The file is located in the root of the repository.

To add a new repository, add a new entry to the `repositories.json` file. 

```json
{
    "repositories": [{
            "repoURL": "https://github.com/app-generator/react-datta-able.git"
        },
        {
            "repoURL": "https://github.com/app-generator/react-berry-dashboard.git"
        },
        {
            "repoURL": "YOUR_REPOSITORY_GIT_URL"
        }
    ]
}
```

## Automated Testing using GH Actions

The ui test tool can be run using GH actions. Using Github Actions, you benefit from parallel builds on different nodejs environment.
```yaml
...
jobs:
  compatibility-check:
    name: Compatibility Check
    runs-on: ubuntu-20.04
    continue-on-error: true

    strategy:
      matrix:
        node-version: [10.x, 12.x, 14.x, 16.x, 18.x]
 ...
```

## Manual Testing
The test can also be run locally. However, the default environment will be the one installed on your machine. 
First, clone the repository.
```shell
git clone https://github.com/app-generator/devtool-ui-tester.git
```
After that, give execution permission to the `report-test-build.sh` file. 
```shell
sudo chmod +x report-test-build.sh
```
And then run the script.
```shell
./report-test-build.sh
```
