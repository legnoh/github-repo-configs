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
  - `ADMIN_BOT_APP_ID` (your GitHub App ID)
  - `ADMIN_BOT_APP_PRIVATE_KEY` (your GitHub App Private key)
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
