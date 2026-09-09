resource "docker_image" "nginx" {
  name         = var.image_name
  keep_locally = true
}

resource "docker_container" "web" {
  name    = var.container_name
  image   = docker_image.nginx.image_id
  restart = "unless-stopped"

  ports {
    internal = var.internal_port
    external = var.external_port
  }
}