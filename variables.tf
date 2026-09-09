variable "container_name" {
  description = "Name of the Docker container"
  type        = string
  default     = "devops-lab-web"
}

variable "internal_port" {
  description = "Internal port exposed by the container"
  type        = number
  default     = 80
}

variable "external_port" {
  description = "External host port mapped to the container"
  type        = number
  default     = 8081
}

variable "image_name" {
  description = "Docker image name and tag to use, must be provided explicitly"
  type        = string
}