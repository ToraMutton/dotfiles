#!/bin/bash
bar=" ▂▃▄▅▆▇█"
dict="s/;//g;"

# Create sed dictionary to replace raw values with bar characters
i=0
while [ $i -lt ${#bar} ]
do
    dict="${dict}s/$i/${bar:$i:1}/g;"
    i=$((i=i+1))
done

# Run cava and pipe through sed
# Ensuring raw output for simpler parsing
cava -p ~/.config/cava/config | sed -u "$dict"
