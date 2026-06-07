ssh root@$1 systemctl stop semaphore
scp semaphore root@$1:/usr/local/bin/semaphore
ssh root@$1 systemctl start semaphore
