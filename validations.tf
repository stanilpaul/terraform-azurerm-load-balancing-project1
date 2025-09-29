variable "name_external_lb" {
  type = string

  validation {
    condition     = length(var.name_external_lb) > 0
    error_message = "Le nom de LB externe ne peut pas être vide."
  }
}
