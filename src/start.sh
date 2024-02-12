#!/bin/bash

rm -f ./tmp/pids/server.pid

# Install node_modules if doesn't exist in container
if [ ! -d "node_modules" ]; then
    npm i
fi

bundle install

bundle exec rake sunspot:solr:start

yarn build --watch & yarn build:css --watch & ./bin/rails server -b "0.0.0.0" && fg 

