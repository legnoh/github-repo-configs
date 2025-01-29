variable "user" {
  type = string
  description = "Target GitHub owner username(for setting CODEOWNERS file)"
}

variable "name" {
  type = string
  description = "Target GitHub repository name"
}

variable "default_branch" {
  type = string
  description = "Git default branch name"
}

variable "topics" {
  type = list(string)
  description = "List of topics for the GitHub repository"
}

variable "pr_job_names" {
  type = list(string)
  description = "List of job names for pull_request & pull_request_target events"
}
