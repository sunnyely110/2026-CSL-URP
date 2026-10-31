#!/bin/bash

DATA_DIR="/mnt/c/Users/soyoo/URP_cdo_data/1031"
cd "${DATA_DIR}" || exit 1

LATS=("45N" "30N" "15N" "0N" "15S" "30S" "45S")

for lat in "${LATS[@]}"; do
    echo ">>> Generating Ensemble Mean for SAI ${lat}..."
    
    FILES=()
    for ens in e02 e03 e04 e05 e06 e07; do
        F="PR_zscore_monthly_${lat}_${ens}.nc"
        if [ -f "${F}" ]; then
            FILES+=("${F}")
        fi
    done

    if [ ${#FILES[@]} -gt 0 ]; then
        cdo -s ensmean "${FILES[@]}" "PR_zscore_monthly_ensmean_${lat}.nc"
        echo "    └─ Created: PR_zscore_monthly_ensmean_${lat}.nc"
    else
        echo "    └─ [Warning] No ensemble files found for ${lat}"
    fi
done
