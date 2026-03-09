#!/bin/bash

for f in *.svg;
do
echo "Changing color of $f ..."
sed -i -e 's/currentColor/#5beedc/g' "$f";
done

