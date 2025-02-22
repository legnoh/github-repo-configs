# github-repo-configs

GitHub auto config setting script with GitHub Actions & [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs).

- Public personal repository are setting automatically [you desired](https://github.com/legnoh/github-repo-configs/blob/main/modules/repo/main.tf).
- States are automatically controlled if you created,archived or deleted repository.

Usage
---

### Topic options

This config uses [**GitHub topics**](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics) for setting options.
If you have any special repository, please set below topic.

- `no-codeowners`: `.github/CODEOWNERS` file isn't created.
- `no-branch-protection`: Branch Protection Rule isn't created.

### Command(local)

```sh
# install gh cli for prepare script
brew install gh
gh auth login

# define env yourself
export GITHUB_OWNER="$(gh api user --jq .login)"
export GITHUB_TOKEN="$(gh auth token)"
export TF_VAR_GITHUB_OWNER="${GITHUB_OWNER}"
export TF_VAR_BUMP_BOT_ID=$(gh api "users/${GITHUB_OWNER}-bump-bot[bot]" | jq -r ".id")
export TF_VAR_AUTOMERGE_BOT_ID=$(gh api "users/${GITHUB_OWNER}-automerge-bot[bot]" | jq -r ".id")
export TF_VAR_DOCKERHUB_USERNAME="..."
export TF_VAR_DOCKERHUB_TOKEN="..."
cat bump-bot-key.pem | jq -Rs '{ BUMP_BOT_PRIVATEKEY: . }' > bump-bot.auto.tfvars.json
cat automerge-bot-key.pem | jq -Rs '{ AUTOMERGE_BOT_PRIVATEKEY: . }' > automerge-bot.auto.tfvars.json

# init & make tfvars file
terraform init
./setup.sh

# apply
terraform apply
```

### GitHub Actions(CI)

- Create [**GitHub App**](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps) for yourself.
  - Change App [Permissions](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/choosing-permissions-for-a-github-app) in Repository scope.
    - Actions: `Read-only`
    - Administration: `Read and write`
    - Contents: `Read and write`
    - Metadata: `Read-only`
    - Workflows: `Read and write`
  - and install to your user.
    - [Installing your own GitHub App - GitHub Docs](https://docs.github.com/en/apps/using-github-apps/installing-your-own-github-app)
- Please set repository secret below.
  - `ADMIN_BOT_APP_ID` (your admin-bot GitHub App ID)
  - `ADMIN_BOT_APP_PRIVATE_KEY` (your admin-bot GitHub App Private key)
  - `BUMP_BOT_APP_ID` (your bump-bot GitHub App ID)
  - `BUMP_BOT_APP_PRIVATE_KEY` (your bump-bot GitHub App Private key)
  - `AUTOMERGE_BOT_APP_ID` (your automerge-bot GitHub App ID)
  - `AUTOMERGE_BOT_PRIVATE_KEY` (your automerge-bot GitHub App Private key)
  - `DOCKERHUB_USERNAME` (your DockerHub username)
  - `DOCKERHUB_TOKEN` (your DockerHub PAT)
  - `PASSWORD` (for encrypt your tfstate/repodata password)
    - In this pipeline, tfstate is stored in Local Backend, then encrypted at the end of the pipeline and uploaded it to Build Artifacts.
    - From the next time, we will call State from the previous Artifacts. Please note the storage deadline for Artifacts.
- Execute `CI` action.

> [!TIP]
> If you debug with GitHub Action's tfstate data, get artifact and decrypt it.
> ```sh
> openssl enc -d -aes256 -pbkdf2 -md sha-256 -in terraform.tfstate.enc -out terraform.tfstate
> ```

## Appendix

> [!NOTE]
> If you do not use a [Signing commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits), be aware that `require_signed_commits` of the brunch protection is obstructed by⁠ `terraform apply`.
> If you commit it via a GitHub App, you can avoid this problem because a commit signature is always given.

### Two GitHub Apps for yourself

For long-term operation of multiple OSS on GitHub, it is recommended to always create two GitHub Apps:

1. **Bump bot**
  - This bot is in charge of the task of creating PRs while updating dependency library versions.
  - Scope:
    - Contents: `Read and write`
    - Metadata: `Read-only`
    - Pull Requests: `Read and write`
1. **Automerge bot**
  - This bot is responsible for automatically merging PRs issued by Dependabot and bump-bot. When merging only PRs, GitHub Actions automatically issues a `GITHUB_TOKEN` by default, making the process straightforward. However, if Auto-Merge is executed using `GITHUB_TOKEN`, triggering an action manually can cause limitations that prevent subsequent jobs (such as push jobs after merging) from running. To prevent this issue in a more general way, a bot is required.
  - Scope:
    - Contents: `Read and write`
    - Metadata: `Read-only`
    - Pull Requests: `Read and write`
1. **Admin bot**
  - This bot is used to perform operations that require change permissions on all repositories, like in this repository. You can also grant these permissions (scope) to the bump bot, but that would give it very broad privileges. By separating the roles of who makes the changes as much as possible, you can minimize the potential negative consequences if any issues arise.
  - Scope:
    - Actions: `Read-only`
    - Administration: `Read and write`
    - Contents: `Read and write`
    - Metadata: `Read-only`
    - Secrets: `Read and write`
    - Variables: `Read and write`
