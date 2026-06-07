set -a; source ../.env; set +a

cd runner

terraform workspace select $1

terraform destroy -auto-approve

cd ../server

terraform workspace select $1

terraform destroy -auto-approve
