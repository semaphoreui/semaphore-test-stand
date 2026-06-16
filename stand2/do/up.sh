set -a; source ../.env; set +a

cd server

if [[ -n "$1" ]]; then
  terraform workspace select $1
fi

terraform apply -auto-approve


web_root=$(terraform output -raw semaphore_url)
echo "Waiting for $web_root to become available..."
deadline=$(( $(date +%s) + 600 ))
until curl -sk -o /dev/null -f "$web_root/api/ping"; do
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "Timed out waiting for $web_root" >&2
    exit 1
  fi
  sleep 10
done
echo "$web_root is available."

cd ..

cd runner

if [[ -n "$1" ]]; then
  terraform workspace select $1
fi

terraform apply -auto-approve
