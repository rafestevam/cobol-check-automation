#!/bin/bash
zowe uss issue ssh "java -jar /z/bin/cobol-check.jar -p $1 -c /z/public/cobol-check.config.properties"
