set -a; source ../.env; set +a

cd server

terraform workspace select $1

terraform apply -auto-approve

cd ../runner

terraform workspace select $1

terraform apply -auto-approve
