variable "GITHUB_OWNER" {
  type = string
  description = "Target GitHub owner username(for setting CODEOWNERS file)"
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
