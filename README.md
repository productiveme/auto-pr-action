# Auto PR Creator GitHub Action

This GitHub Action automatically creates a pull request when a new branch is pushed to your repository.

## Features

- Automatically creates a PR when a branch is pushed
- Extracts issue numbers from branch names (if present)
- Uses issue titles for PR titles when possible
- Adds customizable labels to the PR
- Formats branch names into readable PR titles
- Automatically stacks the PR on the branch it was cut from when both target the same base branch

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
      issues: write
    steps:
      - uses: productiveme/auto-pr-action@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          target_branch: master # Optional, defaults to master
          target_branch_file: .github/base_branch # Optional, path to a file containing the base branch (first line, trimmed). Falls back to target_branch if missing/empty.
          add_labels: WIP # Optional, defaults to WIP
```

## Repository Settings

You also need to enable GitHub Actions to create and approve pull requests in your repository settings:

1. Go to your repository **Settings** → **Actions** → **General**
2. Scroll down to **Workflow permissions**
3. Select **"Read and write permissions"**
4. Check **"Allow GitHub Actions to create and approve pull requests"**

Without these settings, the action won't be able to create PRs even with the correct workflow permissions.

## Inputs

| Input               | Description                                                                                                                | Required | Default  |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------- | -------- | -------- |
| `github_token`      | GitHub token for API access                                                                                                | Yes      | N/A      |
| `target_branch`     | The branch to create the PR against                                                                                        | No       | `master` |
| `target_branch_file`| Path to a file containing the base branch (first non-empty line, trimmed). Overrides `target_branch` when set and non-empty. | No       | `''`     |
| `add_labels`        | Labels to add to the PR (comma-separated)                                                                                  | No       | `WIP`    |
| `auto_stack`        | Stack the PR on the branch it was cut from when that branch converges on the same base branch.                            | No       | `true`   |

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

## Base Branch From File

You can determine the base branch at runtime by pointing `target_branch_file` at a file in the repository whose first non-empty line is the branch name. Whitespace is trimmed.

```yaml
- uses: productiveme/auto-pr-action@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    target_branch_file: .github/base_branch
```

Example `.github/base_branch` file:

```
main
```

If the file is missing or empty, the action falls back to the value of `target_branch` (default `master`) and logs a `::notice::` line. This is useful when the base branch is decided by another workflow step or by a tool that writes the desired target into a known file before this action runs.

## Automatic Stacking

By default (`auto_stack: true`), the action stacks the new PR on the branch it was cut from instead of always targeting the base branch. This keeps the diff of a stacked branch limited to its own changes.

The action resolves the base as follows:

1. Determine the base branch: `target_branch_file` (first non-empty line, trimmed) if set, otherwise `target_branch`.
2. Find the branch this one was cut from: the most recent remote branch (other than the base) whose tip is an ancestor of `HEAD` and that has not already been merged into the base.
3. Walk that branch's own PR base — or its `.github/base_branch` file — up to a root, stopping as soon as the walk reaches the configured base branch. The base branch's own release PR (for example `premium → master`) is not followed. If the root converges on the same base branch, stack the PR on that parent branch. Otherwise fall back to the base branch.

The action makes sure it has the history it needs: if the repository was checked out shallowly, it unshallows it and fetches all remote branches before resolving the base. No `fetch-depth: 0` is required in the consumer workflow.

To disable stacking and always target the resolved base branch, set:

```yaml
- uses: productiveme/auto-pr-action@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    auto_stack: false
```

The resolution is summarised in the workflow run's step summary.

## Troubleshooting

### "Resource not accessible by integration" Error

If you see this error, it means the `GITHUB_TOKEN` doesn't have sufficient permissions. Make sure your workflow includes the necessary permissions:

```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
```

The action requires:
- `contents: read` - To access repository content
- `pull-requests: write` - To create PRs and check for existing ones
- `issues: write` - To add labels to PRs

### Action Says PR Already Exists When It Doesn't

This usually happens due to API permission errors. Check the action logs for "GitHub API error" messages. If you see permission errors, add the permissions section above to your workflow.

### "You do not have permission to create labels" Error

If you see this error, add the `issues: write` permission to your workflow:

```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
```

### Action Can't Create Pull Requests

If the action fails to create PRs with permission errors, check both:

1. **Workflow permissions** (shown above)
2. **Repository settings**: Go to Settings → Actions → General → Workflow permissions and ensure:
   - "Read and write permissions" is selected
   - "Allow GitHub Actions to create and approve pull requests" is checked

## License

MIT
