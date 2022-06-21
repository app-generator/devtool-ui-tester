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

## Manual Testing