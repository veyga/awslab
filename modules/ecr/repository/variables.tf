variable "name" {
  description = "repository name"
  type        = string
}

variable "mutable_tags" {
  description = "tags that may be overwritten (wildcards allowed); every other tag is immutable"
  type        = list(string)
  default     = []
}

variable "keep_images" {
  description = "how many images to keep; older ones are expired (null = keep everything)"
  type        = number
  default     = 20
  nullable    = true
}

variable "force_delete" {
  description = "allow destroying the repository while it still holds images"
  type        = bool
  default     = false
}

variable "tags" {
  description = "aws tags"
  type        = map(string)
}
