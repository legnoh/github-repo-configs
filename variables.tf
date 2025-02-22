variable "GITHUB_OWNER" {
  type        = string
  description = "Target GitHub owner username(for setting CODEOWNERS file)"
}

variable "BUMP_BOT_PRIVATEKEY" {
  type        = string
  sensitive   = true
  description = "Your bump-bot Privatekey"
}

variable "AUTOMERGE_BOT_PRIVATEKEY" {
  type        = string
  sensitive   = true
  description = "Your automerge-bot Privatekey"
}

variable "DOCKERHUB_USERNAME" {
  type        = string
  description = "Your DockerHub username"
}

variable "DOCKERHUB_TOKEN" {
  type        = string
  sensitive   = true
  description = "Your DockerHub Personal Access Token(PAT)"
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
