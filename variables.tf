variable "GITHUB_OWNER" {
  type        = string
  description = "Target GitHub owner username(for setting CODEOWNERS file)"
}

variable "BUMP_BOT_ID" {
  type        = string
  description = "Your bump-bot appid"
}

variable "BUMP_BOT_PRIVATEKEY" {
  type        = string
  sensitive   = true
  description = "Your bump-bot Privatekey"
}

variable "repos" {
  type = list(
    object({
      name           = string,
      default_branch = string,
      topics         = list(string),
      pr_job_names   = list(string)
    })
  )
  description = "List of GitHub repositories information"
}
