resource "github_repository" "repo" {
  name                   = var.name
  allow_auto_merge       = true
  allow_merge_commit     = false
  allow_rebase_merge     = false
  delete_branch_on_merge = true
  has_issues             = true
  has_projects           = false
  has_wiki               = false
  vulnerability_alerts   = true
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      description,
      is_template,
      homepage_url,
      template,
      topics,
    ]
  }
}

resource "github_branch_default" "main" {
  repository = github_repository.repo.name
  branch     = var.default_branch
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_file" "codeowners" {

  count = contains(var.topics, "no-codeowners") ? 0 : 1 

  repository          = github_repository.repo.name
  branch              = github_branch_default.main.branch
  file                = ".github/CODEOWNERS"
  content             = templatefile("${path.module}/templates/.github/CODEOWNERS.tftpl", {user = var.user})
  commit_message      = "[skip ci] update CODEOWNERS"
  overwrite_on_create = true
  lifecycle {
    ignore_changes = [
      commit_message,
    ]
  }
}

resource "github_repository_file" "automerge" {

  count = contains(var.topics, "no-codeowners") ? 0 : 1

  repository          = github_repository.repo.name
  branch              = github_branch_default.main.branch
  file                = ".github/workflows/automerge.yml"
  content             = templatefile("${path.module}/templates/.github/workflows/automerge.yml.tftpl", {user = var.user})
  commit_message      = "[skip ci] update automerge.yml"
  overwrite_on_create = true
  lifecycle {
    ignore_changes = [
      commit_message,
    ]
  }
}

resource "github_repository_file" "uv_locker" {

  count = github_repository.repo.primary_language == "Python" ? 1 : 0

  repository          = github_repository.repo.name
  branch              = github_branch_default.main.branch
  file                = ".github/workflows/uv-lock.yml"
  content             = templatefile("${path.module}/templates/.github/workflows/uv-lock.yml.tftpl", {user = var.user})
  commit_message      = "[skip ci] update uv-lock.yml"
  overwrite_on_create = true
  lifecycle {
    ignore_changes = [
      commit_message,
    ]
  }
}

resource "github_branch_protection" "main" {
  
  count = contains(var.topics, "no-branch-protection") ? 0 : 1

  repository_id    = github_repository.repo.node_id
  pattern          = github_branch_default.main.branch

  allows_force_pushes = true
  allows_deletions = false
  enforce_admins   = false
  
  require_signed_commits = true
  require_conversation_resolution = true
  required_linear_history = true

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
  }
  
  required_status_checks {
    strict   = true
    contexts = var.pr_job_names
  }
}

resource "github_actions_variable" "bump_bot_id" {
  repository       = var.name
  variable_name    = "G_BUMP_BOT_ID"
  value            = var.bump_bot_id
}

resource "github_actions_secret" "bump_bot_privatekey" {
  repository       = var.name
  secret_name      = "G_BUMP_BOT_PRIVATEKEY"
  plaintext_value  = var.bump_bot_privatekey
}

resource "github_actions_variable" "automerge_bot_id" {
  repository       = var.name
  variable_name    = "G_AUTOMERGE_BOT_ID"
  value            = var.automerge_bot_id
}

resource "github_actions_secret" "automerge_bot_privatekey" {
  repository       = var.name
  secret_name      = "G_AUTOMERGE_BOT_PRIVATEKEY"
  plaintext_value  = var.automerge_bot_privatekey
}

resource "github_actions_variable" "dockerhub_username" {
  repository       = var.name
  variable_name    = "G_DOCKERHUB_USERNAME"
  value            = var.dockerhub_username
}

resource "github_actions_secret" "dockerhub_token" {
  repository       = var.name
  secret_name      = "G_DOCKERHUB_TOKEN"
  plaintext_value  = var.dockerhub_token
}
