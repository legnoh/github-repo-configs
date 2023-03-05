# github-repo-configs

[![Badge](https://shields.io/badge/Terraform-app--terraform--io-blueviolet?logo=terraform&style=flat)](https://app.terraform.io/app/lkjio/workspaces/github-repo-configs)


GitHub auto config setting script with GitHub Actions & [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs).

- Public personal repository are setting automatically you desired.
- States are automatically controlled if you created,archived or deleted repository.

Usage
---

### Requirement

- Get [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- Get [Terraform Cloud User API Token](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens).
- Change [Terraform Cloud's Execution Mode](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings#execution-mode) to "Local".

### Command(local)

```sh
export GITHUB_REPOSITORY_OWNER=yourname
export GITHUB_TOKEN="ghp_XXXX"
export TF_CLOUD_ORGANIZATION=yourorg
export TF_WORKSPACE=yourworkspace
export TF_TOKEN_app_terraform_io="XXXXXX......XXXXXX"

terraform init
./.github/workflows/prepare.sh
terraform apply
```

### GitHub Actions(CI)

- Please set secret below.
  - `GITHUB_TOKEN_FOR_TF`
    - Please take care of your token permission(It must be a writable token).
      - Scope: `repo`(all), `read:org` and `read:discussion`
  - `TF_CLOUD_ORGANIZATION`
  - `TF_WORKSPACE`
  - `TF_API_TOKEN`
    - same with `TF_TOKEN_app_terraform_io`
- and execute `terraform plan` & `terraform apply` action.
