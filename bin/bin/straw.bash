#!/bin/bash

cat data.dat | tr '\n' ' '


#tr '\n' ' ' | tr '|' '+' | gsed 's/2016|/2016|\n/g' | gsed 's/2017|/2017|\n/g' | xargs cut -d + -f 1-3