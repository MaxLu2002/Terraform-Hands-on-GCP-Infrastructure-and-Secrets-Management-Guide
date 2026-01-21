
provider "google" {
  project     = jsondecode(file("./files/gcp_key.json")).project_id
  region      = var.region

  credentials = file("./files/gcp_key.json") 
}