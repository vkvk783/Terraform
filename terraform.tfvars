# ── Identity ───────────────────────────────────────────────────
subscription_id    = "b20253a7-bb0f-4f85-91d5-d6ee6fab51e0"   # az account show --query id -o tsv
tenant_id          = "2bfb4170-38cf-4ad0-8815-7d6d2275c69e"   # az account show --query tenantId -o tsv

# ── Global settings ────────────────────────────────────────────
location           = "eastus"
project            = "taskmanager" # Used as prefix in all resource names
admin_ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsq8pgc3KzhTYb0H7EoMimqTjED6Og4Um4V6MFN9/EEjipjcxUqu6dna/VvC+E6MMabigh/vUS18x5fzSvjelVn699/ywblAQPxrpDihrl17BBKmGMT7OB2goJoS/s89t7BwmAxsBjxhyT1JbxM9gqwZ4awH1Lw0mxQP8/FFKT3pVnL13KVzcj/2zWqXW5B1gHgd7RdVcSdmFVG9SX9xPSL4z1i8dtQXUftXF6bJOzMhCnDrLSij0sCiMd7Btd4vd/Qy0URAfW87zletOWQUbzyF6Dz2wjy1mOiu9gREAnyE/JUAMd+vFjjbb/uIiLeXzgEklPc63rM36gc0oPswiQxHIIe8hd5PUIU0XptJOnZGg3JlFna0hDiZzoNjeM63xVPDDS7rc1GuSvGbPGTdUKTWd7UEH1hUO0BVebNByvNYCerNDlHf/rrcm19s5RpYMCZ8ubJeEdCgAuBjPnLQ8JJZ2dx4etqUdl1p+leXoEgSL6ljFFMTbPuxBedXnjvEaurlMqd1GRPKfGmmHEH2/PVlZxy7PPiQZ/nL2jXTyi7b1PQ4+z4TMJHYwXAwV4fhAHchJRNs265RORrznrKYkiJwFR3qOfkLJWlafFrR4y/krMpw7TB/+Jpam+KUjE8NdC4UGRCi0Q+IR7L5my/iqekV9/nEB5RJmrjDUc5vlNAw== kulkarnivivek1992@gmail.com"
jenkins_vm_size    = "Standard_D4s_v3"
# Add this line to terraform/terraform.tfvars
devops_subnet_cidr = "10.0.10.0/24"

# ── All 4 AKS environments ─────────────────────────────────────
environments = {
  dev = {
    node_count  = 2
    vm_size     = "Standard_B2s"
    max_count   = 4
    subnet_cidr = "10.1.0.0/16"
    az_spread   = false
  }
  test = {
    node_count  = 2
    vm_size     = "Standard_B2s"
    max_count   = 4
    subnet_cidr = "10.2.0.0/16"
    az_spread   = false
  }
  uat = {
    node_count  = 3
    vm_size     = "Standard_B2s"
    max_count   = 6
    subnet_cidr = "10.3.0.0/16"
    az_spread   = false
  }
  prod = {
    node_count  = 3
    vm_size     = "Standard_B2s"
    max_count   = 10
    subnet_cidr = "10.4.0.0/16"
    az_spread   = false
  }
}