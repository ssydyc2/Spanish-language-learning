Pull Request Conventions

When asked to create or prepare a pull request, do not try to open the PR on GitHub by default. GitHub CLI, browser login, and API setup are often environment-specific and error-prone.

Instead, print a ready-to-copy PR title and body so the user can create the PR manually in GitHub. Do not run gh pr create, call the GitHub API, or drive a browser to submit the PR unless the user explicitly asks for that after seeing the copyable text.

Use this classification prefix system for PR titles:

[Feature] - Adding or updating functionality
[Bug Fix] - Fixing broken or incorrect behavior
[Refactoring] - Code restructuring without changing functionality
[Documentation] - Updates to docs, comments, or README
Print PR text in this exact shape, with the body always provided as a fenced Markdown block so it can be copied directly into GitHub:

Title: [Feature] Short imperative title

Body:
```markdown
### Context
- Concise explanation of why this PR exists.

### Changes
- Concrete change made.
- Another concrete change made.
```
If a branch has already been pushed, include the PR URL separately after the copyable title/body. Do not let a missing PR URL block providing the copyable text.
