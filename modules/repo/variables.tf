variable "user" {
  type = string
}

variable "name" {
  type = string
}

variable "default_branch" {
  type = string
}

variable "topics" {
  type = list(string)
}

variable "pr_job_names" {
  type = list(string)
}
