variable "namespace" {
  description = "namespace for install"
  type        = string
}

variable "create_namespace" {
  description = "create new namespace for install"
  type        = bool
}

variable "install_crds" {
  description = "install CRDs"
  type        = bool
}
