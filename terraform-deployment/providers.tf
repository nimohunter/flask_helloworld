provider "kubernetes" {
  # Configuration options
  config_path = "~/.kube/config" # Path to your kubeconfig file
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
