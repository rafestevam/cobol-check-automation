#!/bin/bash

# Check Java availability
java -version

# Change to cobol-check directory
cd cobol-check
echo "Changed to $(pwd)"
ls -la

# Make cobolcheck executable
chmod +x cobolcheck.sh
echo "Made cobolcheck executable"

# Make script in scripts directory executable
cd scripts
echo "Changed to $(pwd)"
chmod +x linux_gnucobol_run_tests
echo "Made linux_gnucobol_run_tests executable"
cd ..

# Function to run cobol-check and copy files
run_cobolcheck() {
    program=$1
    echo "Running cobolcheck for $program"

    # Run cobolcheck, but don't exit if it fails
    ./cobolcheck.sh $program
    echo "Cobolcheck execution completed for $program (exceptions may have ocurred)"

    # Check if CC##99.CBL was created, regadless of cobolcheck exit status
    if [ -f "CC##99.CBL" ]; then
        # Copy to MVS dataset
        if cp CC##99.CBL "//'${ZOWE_USERNAME}.CBL($program)'"; then
            echo "Copied CC##99.CBL to ${ZOWE_USERNAME}.CBL($program)"
        else
            echo "Failed to copy CC##99.CBL to ${ZOWE_USERNAME}.CBL($program)"
        fi
    else
        echo "CC##99.CBL not found for $program"
    fi

    # Copy the JCL file if it exists
    if [ -f "${program}.JCL" ]; then
        if cp ${program}.JCL "//'${ZOWE_USERNAME}.JCL($program)'"; then
            echo "Copied ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
        else
            echo "Failed to copy ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
        fi
    else
        echo "${program}.JCL not found"
    fi
}

# Run each program
for program in NUMBERS EMPPAY DEPTPAY; do
    zowe uss issue ssh "cd /z/z83784/cobolcheck && $(declare -f run_cobolcheck); run_cobolcheck $program"
done

echo "Mainframe operations completed"