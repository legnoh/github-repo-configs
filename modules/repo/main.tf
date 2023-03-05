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
  content             = "* @${var.user}\n"
  commit_message      = "[skip ci] update CODEOWNERS"
  overwrite_on_create = false
  lifecycle {
    prevent_destroy = true
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
    strict   = false
    contexts = ( contains(var.topics, "netlify")
        ? ["netlify/${github_repository.repo.name}/deploy-preview"]
        : null
    )
  }
}
