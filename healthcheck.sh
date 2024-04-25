#!/bin/bash

# Check if Puma server is running
if ! pgrep -f "puma" > /dev/null; then
    echo "Puma server is not running."
    exit 1
fi

# Check if Puma server is responding to requests
if ! curl -sSf http://localhost:3000 > /dev/null; then
    echo "Puma server is not responding to requests."
    exit 1
fi

echo "Puma server is running and responding to requests."
exit 0
