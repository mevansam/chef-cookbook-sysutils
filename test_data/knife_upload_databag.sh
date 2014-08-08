#!/bin/bash

echo Y | knife data bag delete users test
knife data bag create users
knife data bag from file users ./user_data_bag.json --secret 1234
