locals {
  project_id = jsondecode(file("./files/gcp_key.json")).project_id
}

output "infra" {
  value = {
    public_vm_login = "ssh -i ./keys/id_rsa terraform_test@${module.gce.output.external_id}"
    public_vm_create_ssh_key = "gcloud compute ssh ${module.gce.output.name} --zone=${module.gce.output.zone} --quiet"
    gcloud_login_command = <<-EOT
    
    gcloud auth activate-service-account --key-file="./files/gcp_key.json"
    gcloud config set project ${local.project_id}
    EOT
  }
}