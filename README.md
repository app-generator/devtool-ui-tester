# DevTool UI Tester

This [developer tool](https://appseed.us/developer-tools/) provides a simple way to ensure compatibilty of React projects accross different Node environments provided by [AppSeed](https://appseed.us/)

<br />

## ✨ How to use it

- 👉 [Fork the project](https://github.com/app-generator/devtool-ui-tester/fork) 
- 👉 Edit `repositories.json` and add your repositories to test the build
- 👉 Edit [compatibility.yaml](https://github.com/app-generator/devtool-ui-tester/blob/main/.github/workflows/compatibility.yaml#L18) and specify the Node verison
  - multiple values supported: `node-version: [16.x, 18.x]`
- 👉 Edit the builder in [report-test-build.sh](https://github.com/app-generator/devtool-ui-tester/blob/b6cbd7ae0ce9557151195b5242c6ecc491354b0b/report-test-build.sh#L37)
  - `Yarn` or `NPM` 

<br />

## ✨ Installation

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

## ✨ Automated Testing using GH Actions

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
