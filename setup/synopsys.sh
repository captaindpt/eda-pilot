#!/usr/bin/env bash
# Synopsys DC/PT/LC/Sentaurus setup for bash.
# Source this: source setup/synopsys.sh

export CMC_HOME="${CMC_HOME:-/CMC}"
export SYNOPSYS_TOP="${CMC_HOME}/tools/synopsys"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-6053@licaccess.cmc.ca}"

export DC_HOME="${SYNOPSYS_TOP}/syn_vW-2024.09-SP2/syn/W-2024.09-SP2"
export PT_HOME="${SYNOPSYS_TOP}/prime_vW-2024.09-SP2/prime/W-2024.09-SP2"
export LC_HOME="${SYNOPSYS_TOP}/lc_vW-2024.09-SP2/lc/W-2024.09-SP2"
export STROOT="${SYNOPSYS_TOP}/sentaurus_vX_2025.09/sentaurus"

prepend_path() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) export PATH="$1:${PATH}" ;;
  esac
}

prepend_path "${DC_HOME}/bin"
prepend_path "${PT_HOME}/bin"
prepend_path "${LC_HOME}/bin"

if [[ -d "${STROOT}/bin" ]]; then
  prepend_path "${STROOT}/bin"
fi

echo "Synopsys tools ready"
echo "  dc_shell: $(which dc_shell 2>/dev/null || echo 'not found')"
echo "  pt_shell: $(which pt_shell 2>/dev/null || echo 'not found')"
echo "  lc_shell: $(which lc_shell 2>/dev/null || echo 'not found')"
echo "  sdevice:  $(which sdevice 2>/dev/null || echo 'not found')"
echo "  license:  SNPSLMD_LICENSE_FILE=${SNPSLMD_LICENSE_FILE}"
