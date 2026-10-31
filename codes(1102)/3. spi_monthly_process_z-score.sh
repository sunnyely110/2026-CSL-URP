#!/bin/bash

set -e

DATA_DIR="/mnt/c/Users/soyoo/URP_cdo_data/1031"
TARGET_GRID="${DATA_DIR}/target_grid.txt"

SSP_YMONMEAN="${DATA_DIR}/PR_ymonmean_mmday_SSP.nc"
YMONSTD_SAFE="${DATA_DIR}/PR_ymonstd_safe.nc"

LATS=("45N" "30N" "15N" "0N" "15S" "30S" "45S")
ENSEMBLES=("e02" "e03" "e04" "e05" "e06" "e07")

cd "${DATA_DIR}" || exit 1

echo "======================================================================"
echo " Starting CESM2 Ensemble Monthly Z-score Processing (360 Timesteps)"
echo "======================================================================"

for lat in "${LATS[@]}"; do
    for ens in "${ENSEMBLES[@]}"; do
        
        INPUT_NC="CESM2.INJANN${lat}.${ens}.PRECT.20350101_20691231.nc"
        
        if [ ! -f "${INPUT_NC}" ]; then
            echo " 파일 없어서 스킵: ${INPUT_NC}"
            continue
        fi

        echo ">>> Processing Scenario: SAI ${lat} | Ensemble: ${ens}"

        TMP_REMAPPED="tmp_m_${lat}_${ens}_remapped.nc"
        TMP_30Y="tmp_m_${lat}_${ens}_30y.nc"
        TMP_MMDAY="tmp_m_${lat}_${ens}_mmday.nc"
        TMP_SUB="tmp_m_${lat}_${ens}_sub.nc"
        
        OUT_ZSCORE="PR_zscore_monthly_${lat}_${ens}.nc"

        cdo -s remapbil,"${TARGET_GRID}" "${INPUT_NC}" "${TMP_REMAPPED}"
        cdo -s seldate,2040-01-01,2069-12-31 "${TMP_REMAPPED}" "${TMP_30Y}"

        cdo -s mulc,86400000 "${TMP_30Y}" "${TMP_MMDAY}"

        cdo -s ymonsub -selvar,x "${TMP_MMDAY}" -selvar,pr "${SSP_YMONMEAN}" "${TMP_SUB}"

        cdo -s ymondiv -selvar,x "${TMP_SUB}" -selvar,pr "${YMONSTD_SAFE}" "${OUT_ZSCORE}"

        rm -f tmp_m_${lat}_${ens}_*.nc

        echo "    └─ Completed: ${OUT_ZSCORE}"
    done
done

echo "======================================================================"
echo " All Monthly Z-score processing successfully finished!"
echo "======================================================================"
