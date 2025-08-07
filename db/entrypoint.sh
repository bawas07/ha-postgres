#!/bin/bash
set -e

# Ensure the data directory exists and has proper permissions
mkdir -p /home/patroni/pgdata
chmod 700 /home/patroni/pgdata

# Substitute environment variables in the patroni template
envsubst < /home/patroni/patroni-template.yml > /home/patroni/patroni.yml

# Start patroni
exec patroni /home/patroni/patroni.yml
