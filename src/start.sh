#!/bin/bash

rm -f ./tmp/pids/server.pid

# Install node_modules if doesn't exist in container
if [ ! -d "node_modules" ]; then
    npm i
fi

#bundle install
rm -rf ./solr/pids/development/sunspot-solr-development.pid
bundle exec rake sunspot:solr:start &

npm run build & npm run build:css & ./bin/rails server -b "0.0.0.0" && fg 

