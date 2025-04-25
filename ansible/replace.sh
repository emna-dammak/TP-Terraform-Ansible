#!/bin/bash
# Script pour mettre à jour l'inventaire Ansible avec l'IP et les identifiants de la VM Azure

# Récupérer l'IP publique et le nom d'utilisateur depuis les sorties Terraform
IP_ADDRESS=$(terraform output -raw public_ip_address -state=../terraform/terraform.tfstate)
USERNAME=$(terraform output -raw vm_username  -state=../terraform/terraform.tfstate)
PASSWORD=$(terraform output -raw vm_password  -state=../terraform/terraform.tfstate)

# Créer le fichier d'inventaire
cat > inventory.ini << EOF
[web]
azure-vm ansible_host=$IP_ADDRESS ansible_user=$USERNAME ansible_password=$PASSWORD ansible_connection=ssh ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Inventory file updated with IP: $IP_ADDRESS and credentials"