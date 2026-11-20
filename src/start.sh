#!/bin/bash

RAILS_ENV=${RAILS_ENV:-development}
export RAILS_ENV

rm -f ./tmp/pids/server.pid

# Install node_modules if doesn't exist in container
if [ ! -d "node_modules" ]; then
    npm i
fi

#bundle install

if [ "$RAILS_ENV" = "production" ]; then
    # Solr cores are not tracked in git: create the production core on first start
    if [ ! -f ./solr/production/core.properties ]; then
        mkdir -p ./solr/production
        printf 'name=production\nconfigSet=sunspot\ndataDir=./data\n' > ./solr/production/core.properties
    fi

    # One-shot JS/CSS build (no --watch), then precompile into public/assets.
    # SKIP_*_BUILD stops assets:precompile from calling the --watch npm scripts, which never exit.
    ./node_modules/.bin/esbuild app/javascript/*.* --bundle --outdir=app/assets/builds || exit 1
    ./node_modules/.bin/sass ./app/assets/stylesheets/application.bootstrap.scss:./app/assets/builds/application.css --no-source-map --load-path=node_modules || exit 1
    SKIP_JS_BUILD=1 SKIP_CSS_BUILD=1 ./bin/rails assets:precompile || exit 1
fi

rm -f ./solr/pids/$RAILS_ENV/sunspot-solr-$RAILS_ENV.pid
bundle exec rake sunspot:solr:start &
rails run_gwas 2>&1 > log/run_gwas.log &

if [ "$RAILS_ENV" = "production" ]; then
    exec ./bin/rails server -b "0.0.0.0"
else
    npm run build & npm run build:css & ./bin/rails server -b "0.0.0.0" && fg
fi
