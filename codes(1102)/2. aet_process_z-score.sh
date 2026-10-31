#!/bin/bash
set -e

export HDF5_DISABLE_VERSION_CHECK=1
export HDF5_USE_FILE_LOCKING=FALSE

DATA_DIR="/mnt/c/Users/soyoo/URP_cdo_data/1031"
TARGET_GRID="${DATA_DIR}/target_grid.txt"

SSP_HFLS_YSEAS="${DATA_DIR}/HFLS_yseasmean_SSP.nc"

AET_YSEASSTD_SAFE="${DATA_DIR}/AET_yseasstd_safe.nc"

LATS=("45N" "30N" "15N" "0N" "15S" "30S" "45S")
ENSEMBLES=("e02" "e03" "e04" "e05" "e06" "e07")

cd "${DATA_DIR}" || exit 1

echo "======================================================================"
echo " Starting CESM2 Ensemble Seasonal AET Z-score Processing"
echo "======================================================================"

for lat in "${LATS[@]}"; do
    for ens in "${ENSEMBLES[@]}"; do
        
        INPUT_NC="CESM2.INJANN${lat}.${ens}.LHFLX.20350101_20691231.nc"
        
        if [ ! -f "${INPUT_NC}" ]; then
            echo " 파일 없어서 스킵: ${INPUT_NC}"
            continue
        fi

        echo ">>> Processing: AET SAI ${lat} | Ensemble: ${ens}"

        TMP_REMAPPED="tmp_aet_${lat}_${ens}_remapped.nc"
        TMP_30Y="tmp_aet_${lat}_${ens}_30y.nc"
        TMP_YSEAS="tmp_aet_${lat}_${ens}_yseasmean.nc"
        TMP_SUB="tmp_aet_${lat}_${ens}_sub.nc"
        TMP_MMDAY="tmp_aet_${lat}_${ens}_mmday.nc"
        
        OUT_ZSCORE="AET_zscore_yseasmean_${lat}_${ens}.nc"

        cdo -s remapbil,"${TARGET_GRID}" "${INPUT_NC}" "${TMP_REMAPPED}"
        cdo -s seldate,2040-01-01,2069-12-31 "${TMP_REMAPPED}" "${TMP_30Y}"

        cdo -s yseasmean "${TMP_30Y}" "${TMP_YSEAS}"

        cdo -s sub "${TMP_YSEAS}" "${SSP_HFLS_YSEAS}" "${TMP_SUB}"

        cdo -s expr,"aet=x*86400/2501000" "${TMP_SUB}" "${TMP_MMDAY}"

        cdo -s div -selvar,aet "${TMP_MMDAY}" -selvar,aet "${AET_YSEASSTD_SAFE}" "${OUT_ZSCORE}"

        rm -f tmp_aet_${lat}_${ens}_*.nc

        echo "    └─ Completed: ${OUT_ZSCORE}"
    done
done

echo "======================================================================"
echo " All Ensemble AET Z-score processing successfully finished!"
echo "======================================================================"
