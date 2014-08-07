#!/bin/bash

echo Y | knife data bag delete users osenvtest
knife data bag create users
knife data bag from file users ./user_data_bag.json --secret 1234

echo Y | knife data bag delete service_endpoints qip
knife data bag create service_endpoints
knife data bag from file service_endpoints ./qip_data_bag.json --secret 1234
