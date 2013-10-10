#!/bin/bash

./tools/module_commits.rb modules/ > all_mods.txt &
./tools/module_commits.rb modules/exploits > exp_mods.txt &
./tools/module_commits.rb modules/auxiliary > aux_mods.txt &
./tools/module_commits.rb modules/post > pst_mods.txt &
./tools/module_commits.rb modules/payloads > pay_mods.txt &

