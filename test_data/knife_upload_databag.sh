#!/bin/bash

echo Y | knife data bag delete users

knife data bag create users
knife data bag from file users ./user_data_bag.json --secret 1234