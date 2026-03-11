#!/bin/bash
# Cadence IC23 + Spectre23 setup for bash
# Source this: source setup/cadence.sh

export CMC_HOME=/CMC
export CDS_TOP_DIR=/CMC/tools/cadence

# IC23 (Virtuoso)
export CMC_CDS_IC_HOME=${CDS_TOP_DIR}/IC23.10.140_lnx86
export CDS_HOME=$CMC_CDS_IC_HOME
export CDSHOME=$CMC_CDS_IC_HOME
export CDS_INST_DIR=$CMC_CDS_IC_HOME

# Spectre23
export SPECTRE_HOME=${CDS_TOP_DIR}/SPECTRE23.10.802_lnx86

# PATH setup
export PATH=${CMC_CDS_IC_HOME}/bin:${PATH}
export PATH=${CMC_CDS_IC_HOME}/tools.lnx86/bin:${PATH}
export PATH=${CMC_CDS_IC_HOME}/tools.lnx86/dfII/bin:${PATH}
export PATH=${SPECTRE_HOME}/tools.lnx86/bin:${PATH}
export PATH=${SPECTRE_HOME}/tools.lnx86/spectre/bin:${PATH}

# Library setup - point to our working library
export CDS_LIB_PATH=${HOME}/cds.lib

# CMC default license server (set only if not already provided)
if [[ -z "${LM_LICENSE_FILE:-}" && -z "${CDS_LIC_FILE:-}" ]]; then
  export CDS_LIC_FILE=6055@licaccess.cmc.ca
fi

echo "Cadence IC23.10.140 + Spectre23.10.802 ready"
echo "  virtuoso: $(which virtuoso 2>/dev/null || echo 'not found')"
echo "  ocean:    $(which ocean 2>/dev/null || echo 'not found')"
echo "  spectre:  $(which spectre 2>/dev/null || echo 'not found')"
if [[ -n "${LM_LICENSE_FILE:-}" || -n "${CDS_LIC_FILE:-}" ]]; then
  echo "  license:  LM_LICENSE_FILE=${LM_LICENSE_FILE:-<unset>} CDS_LIC_FILE=${CDS_LIC_FILE:-<unset>}"
else
  echo "  license:  not set (export LM_LICENSE_FILE or CDS_LIC_FILE)"
fi
