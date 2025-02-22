module "repos" {
  for_each                 = { for repo in var.repos : repo.name => repo }
  source                   = "./modules/repo"
  user                     = var.GITHUB_OWNER
  name                     = each.value.name
  default_branch           = each.value.default_branch
  topics                   = each.value.topics
  pr_job_names             = each.value.pr_job_names
  github_actions_app_id    = data.github_app.github_actions.id
  admin_bot_id             = data.github_app.admin_bot.id
  bump_bot_id              = data.github_app.bump_bot.id
  bump_bot_privatekey      = var.BUMP_BOT_PRIVATEKEY
  automerge_bot_id         = data.github_app.automerge_bot.id
  automerge_bot_privatekey = var.AUTOMERGE_BOT_PRIVATEKEY
  dockerhub_username       = var.DOCKERHUB_USERNAME
  dockerhub_token          = var.DOCKERHUB_TOKEN
}

data "github_app" "github_actions" {
  slug = "github-actions"
}

data "github_app" "admin_bot" {
  slug = "${var.GITHUB_OWNER}-admin-bot"
}

data "github_app" "bump_bot" {
  slug = "${var.GITHUB_OWNER}-bump-bot"
}

data "github_app" "automerge_bot" {
  slug = "${var.GITHUB_OWNER}-automerge-bot"
}
