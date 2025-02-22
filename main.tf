module "repos" {
  for_each                 = { for repo in var.repos : repo.name => repo }
  source                   = "./modules/repo"
  user                     = var.GITHUB_OWNER
  name                     = each.value.name
  default_branch           = each.value.default_branch
  topics                   = each.value.topics
  pr_job_names             = each.value.pr_job_names
  bump_bot_id              = var.BUMP_BOT_ID
  bump_bot_privatekey      = var.BUMP_BOT_PRIVATEKEY
  automerge_bot_id         = var.AUTOMERGE_BOT_ID
  automerge_bot_privatekey = var.AUTOMERGE_BOT_PRIVATEKEY
  dockerhub_username       = var.DOCKERHUB_USERNAME
  dockerhub_token          = var.DOCKERHUB_TOKEN
}
