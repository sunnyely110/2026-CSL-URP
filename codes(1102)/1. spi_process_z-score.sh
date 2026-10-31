#!/bin/bash
set -e

DATA_DIR="/mnt/c/Users/soyoo/URP_cdo_data/1031"
TARGET_GRID="${DATA_DIR}/target_grid.txt"

SSP_YSEASMEAN="${DATA_DIR}/PR_yseasmean_mmday_SSP.nc"

YSEASSTD_SAFE="${DATA_DIR}/PR_yseasstd_safe.nc"

LATS=("45N" "30N" "15N" "0N" "15S" "30S" "45S")
ENSEMBLES=("e02" "e03" "e04" "e05" "e06" "e07")

cd "${DATA_DIR}" || exit 1

echo "======================================================================"
echo " Starting CESM2 Ensemble Seasonal Z-score Processing"
echo "======================================================================"

for lat in "${LATS[@]}"; do
    for ens in "${ENSEMBLES[@]}"; do
        
        INPUT_NC="CESM2.INJANN${lat}.${ens}.PRECT.20350101_20691231.nc"
        
        if [ ! -f "${INPUT_NC}" ]; then
            echo " 파일이 없어서 스킵: ${INPUT_NC}"
            continue
        fi

        echo ">>> Processing: SAI ${lat} | Ensemble: ${ens}"

        TMP_REMAPPED="tmp_${lat}_${ens}_remapped.nc"
        TMP_30Y="tmp_${lat}_${ens}_30y.nc"
        TMP_YSEAS="tmp_${lat}_${ens}_yseasmean.nc"
        TMP_SUB="tmp_${lat}_${ens}_sub.nc"
        TMP_MMDAY="tmp_${lat}_${ens}_mmday.nc"
        
        OUT_ZSCORE="PR_zscore_yseasmean_${lat}_${ens}.nc"

        cdo -s remapbil,"${TARGET_GRID}" "${INPUT_NC}" "${TMP_REMAPPED}"
        cdo -s seldate,2040-01-01,2069-12-31 "${TMP_REMAPPED}" "${TMP_30Y}"

        cdo -s yseasmean "${TMP_30Y}" "${TMP_YSEAS}"

        cdo -s mulc,86400000 "${TMP_YSEAS}" "${TMP_MMDAY}"

        cdo -s sub "${TMP_MMDAY}" "${SSP_YSEASMEAN}" "${TMP_SUB}"

        cdo -s div -selvar,x "${TMP_SUB}" -selvar,pr "${YSEASSTD_SAFE}" "${OUT_ZSCORE}"

        rm -f tmp_${lat}_${ens}_*.nc

        echo "    └─ Completed: ${OUT_ZSCORE}"
    done
done

echo "======================================================================"
echo " All Ensemble Z-score processing successfully finished!"
echo "======================================================================"
