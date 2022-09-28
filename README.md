# DevTool UI Tester

This [developer tool](https://appseed.us/developer-tools/) provides a simple way to ensure compatibilty of React projects accross different Node environments provided by [AppSeed](https://appseed.us/)

<br />

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

<br />

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

<br />

--- 
DevTool UI Tester - Open-Source developer tool provided by [AppSeed](https://appseed.us/)
