set -a; source ../.env; set +a

cd runner

terraform workspace select $1
terraform state list | grep -v -E "digitalocean_certificate|digitalocean_domain|cloudflare_record" | awk '{print "-target=" $0}'
terraform destroy $TARGETS -auto-approve

cd ../server

terraform workspace select $1

terraform destroy -auto-approve
