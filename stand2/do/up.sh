set -a; source ../.env; set +a

cd server

terraform workspace select $1

terraform apply -auto-approve

# Wait until the load balancer host answers before bringing up the runners,
# which register against the Semaphore API on boot. Poll the DNS name (not the
# IP) so we also wait for the delegated zone to propagate.
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

cd ../runner

terraform workspace select $1



terraform apply -auto-approve
