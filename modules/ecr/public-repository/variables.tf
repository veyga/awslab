variable "name" {
  description = "repository name, e.g. charts/veyga-kargo"
  type        = string
}

variable "description" {
  description = "shown on the repository's public gallery page"
  type        = string
  default     = ""
}

variable "tags" {
  description = "aws tags"
  type        = map(string)
}
