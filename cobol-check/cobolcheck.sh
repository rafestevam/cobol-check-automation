#!/bin/bash

while getopts "p:" opt; do
  case $opt in
    p) PROGRAMS="$OPTARG" ;;
    *) echo "Usage: $0 -p <program_name>"; exit 1 ;;
  esac
done

java -jar /z/bin/cobol-check.jar -c /z/public/cobol-check.config.properties -p "$PROGRAMS"
