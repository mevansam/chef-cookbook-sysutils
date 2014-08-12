#!/bin/bash

echo Y | knife data bag delete users "test._default"
knife data bag create users
knife data bag from file users ./data-bag_user.json --secret 1234
