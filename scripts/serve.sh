#!/usr/bin/env bash

cd "$(dirname "$0")"
cd ../src/build
http-server -p 8095 --cors

