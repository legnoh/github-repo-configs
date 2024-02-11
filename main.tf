data "github_user" "current" {
  username = ""
}

module "repos" {
  for_each       = { for repo in var.repos : repo.name => repo }
  source         = "./modules/repo"
  user           = data.github_user.current.login
  name           = each.value.name
  default_branch = each.value.default_branch
  topics         = each.value.topics
  pr_job_names   = each.value.pr_job_names
}
