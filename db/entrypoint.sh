#!/bin/bash
set -e

# Substitute environment variables in the patroni template
envsubst < /home/patroni/patroni-template.yml > /home/patroni/patroni.yml

# Start patroni
exec patroni /home/patroni/patroni.yml
