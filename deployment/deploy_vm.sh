#!/bin/bash

rm /tmp/blue_mint.tar.gz
tar --exclude-from='deployment/exclude.txt' --no-xattrs -czvf /tmp/blue_mint.tar.gz . && \
scp /tmp/blue_mint.tar.gz root@digital-ocean:/tmp && \
ssh digital-ocean << EOF
rm -rf ~/sites/blue_mint/
mkdir -p ~/sites/blue_mint/
tar -xzvf /tmp/blue_mint.tar.gz -C ~/sites/blue_mint && \
rm /tmp/blue_mint.tar.gz && \
cd ~/sites/blue_mint/ && \
asdf local elixir 1.16 && \
asdf local erlang 26.2.5.3 && \
MIX_ENV=prod mix setup && \
MIX_ENV=prod mix assets.deploy && \
MIX_ENV=prod mix phx.gen.release && \
MIX_ENV=prod mix release && \
PHX_SERVER=true ~/sites/blue_mint/_build/prod/rel/blue_mint/bin/blue_mint daemon && \
PHX_SERVER=true ~/sites/blue_mint/_build/prod/rel/blue_mint/bin/blue_mint restart
EOF
