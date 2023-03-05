variable "repos" {
  type = list(
    object({
      name           = string,
      default_branch = string,
      topics         = list(string)
    })
  )
}
