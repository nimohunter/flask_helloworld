resource "helm_release" "ml_api" {
  name       = "ml-api"
  namespace  = "dev"
  repository = "https://example.com/helm-charts" # URL of your Helm chart repository
  chart      = "helm-flask-helloworld"
  version    = "1.0.0"

  set {
    name  = "image.tag"
    value = "dev"
  }

  # Use a file for values
  values = [
    file("${path.module}/values-dev.yaml")
  ]
}
