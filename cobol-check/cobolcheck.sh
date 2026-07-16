#!/bin/bash
zowe uss issue ssh "cd /z/z83784/cobolcheck && java -jar /z/bin/cobol-check.jar -p $1 -c /z/public/cobol-check.config.properties"
