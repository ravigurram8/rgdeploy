#!/bin/bash

jq -r '.Products | map( (.ami_id_list |= ( map_values(to_entries ) | flatten)) )'