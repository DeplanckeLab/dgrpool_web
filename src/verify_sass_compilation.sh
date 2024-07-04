#!/bin/bash

# Run the sass command
./node_modules/.bin/sass ./app/assets/stylesheets/application.bootstrap.scss:./app/assets/builds/application.css --no-source-map --load-path=node_modules

# Check if the CSS file was generated
if [ -f "./app/assets/builds/application.css" ]; then
    echo "application.css has been generated."
    echo "Contents of application.css:"
    cat ./app/assets/builds/application.css
else
    echo "Error: application.css was not generated."
fi
