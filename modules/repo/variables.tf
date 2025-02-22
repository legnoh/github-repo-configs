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

variable "bump_bot_id" {
  type = string
  description = "Bump bot appid"
}

variable "bump_bot_privatekey" {
  type = string
  sensitive = true
  description = "Bump bot privatekey"
}

variable "automerge_bot_id" {
  type = string
  description = "Automerge bot appid"
}

variable "automerge_bot_privatekey" {
  type = string
  sensitive = true
  description = "Automerge bot privatekey"
}

variable "dockerhub_username" {
  type = string
  description = "Your DockerHub username"
}

variable "dockerhub_token" {
  type = string
  sensitive = true
  description = "Your DockerHub Personal Access Token(PAT)"
}
