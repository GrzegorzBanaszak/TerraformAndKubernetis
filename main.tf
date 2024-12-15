provider "docker"{
}


locals {
  images_dir = "${path.root}/images"
  build_images = [
    docker_image.node_app.image_id
  ]
}


resource "docker_image" "node_app"{
  name = "node-app"
  build {
    context = "${local.images_dir}/node-app"
    tag = ["node-app:test"]
  }
}

resource "docker_container" "web_app" {
  name = "web_app"
  image = docker_image.node_app.image_id
  ports {
    internal = 3000
    external = 3000
  }
}
