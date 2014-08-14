#!/bin/bash

echo Y | knife data bag delete "users-_default" "test"
knife data bag create "users-_default"
knife data bag from file "users-_default" ./data-bag_user.json --secret 1234
