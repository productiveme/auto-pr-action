# Auto PR Creator GitHub Action

This GitHub Action automatically creates a pull request when a new branch is pushed to your repository.

## Features

- Automatically creates a PR when a branch is pushed
- Extracts issue numbers from branch names (if present)
- Uses issue titles for PR titles when possible
- Adds customizable labels to the PR
- Formats branch names into readable PR titles

## Usage

Create a workflow file (e.g., `.github/workflows/auto-pr.yml`) in your repository:

```yaml
name: Auto Pull Request
on:
  push:
    branches-ignore:
      - legacy
      - master
      - staging

jobs:
  auto-pull-request:
    name: Create Auto PR
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: vatfree/auto-pr-action@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          target_branch: master # Optional, defaults to master
          add_labels: WIP # Optional, defaults to WIP
```

## Inputs

| Input           | Description                               | Required | Default  |
| --------------- | ----------------------------------------- | -------- | -------- |
| `github_token`  | GitHub token for API access               | Yes      | N/A      |
| `target_branch` | The branch to create the PR against       | No       | `master` |
| `add_labels`    | Labels to add to the PR (comma-separated) | No       | `WIP`    |

## Branch Name Handling

The action handles branch names in two ways:

1. If the branch name follows the pattern `type/123-description` (where 123 is a number), it will:

   - Extract the issue number (123)
   - Use the issue title as the PR title
   - Add "Fixes #123" to the PR description

2. For all other branch names:
   - Removes any prefix before `/` (if present)
   - Replaces dashes with spaces
   - Uses the formatted branch name as the PR title

## Troubleshooting

### "Resource not accessible by integration" Error

If you see this error, it means the `GITHUB_TOKEN` doesn't have sufficient permissions. Make sure your workflow includes the necessary permissions:

```yaml
permissions:
  contents: read
  pull-requests: write
```

The action requires:
- `contents: read` - To access repository content
- `pull-requests: write` - To create PRs and check for existing ones

### Action Says PR Already Exists When It Doesn't

This usually happens due to API permission errors. Check the action logs for "GitHub API error" messages. If you see permission errors, add the permissions section above to your workflow.

## License

MIT
