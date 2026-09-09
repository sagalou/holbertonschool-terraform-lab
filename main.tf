resource "docker_image" "nginx" {
  name         = "nginx:1.27-alpine"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = "devops-lab-web"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }
}
