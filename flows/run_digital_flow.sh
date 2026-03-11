#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CADENCE_SETUP="$REPO_ROOT/setup/cadence.sh"

DC_BIN="/CMC/tools/synopsys/syn_vW-2024.09-SP2/syn/W-2024.09-SP2/bin/dc_shell"
GENUS_BIN="/CMC/tools/cadence/GENUS21.17.000_lnx86/tools.lnx86/bin/genus"
XRUN_BIN="/CMC/tools/cadence/XCELIUMMAIN25.09.001_lnx86/tools.lnx86/bin/xrun"
INNOVUS_BIN="/CMC/tools/cadence/INNOVUS21.17.000_lnx86/tools.lnx86/bin/innovus"
PT_BIN="/CMC/tools/synopsys/prime_vW-2024.09-SP2/prime/W-2024.09-SP2/bin/pt_shell"
LC_BIN="/CMC/tools/synopsys/lc_vW-2024.09-SP2/lc/W-2024.09-SP2/bin/lc_shell"
PEGASUS_BIN="/CMC/tools/cadence/PEGASUS23.26.000_lnx86/tools.lnx86/bin/pegasus"

DC_SETUP="/CMC/scripts/synopsys.syn.2024.09-SP2.csh"
GENUS_SETUP="/CMC/scripts/cadence.genus21.17.000.csh"
PT_SETUP="/CMC/scripts/synopsys.prime.2024.09-SP2.csh"

DC_TARGET_LIB="${DC_TARGET_LIB:-/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib}"
DC_SYNTH_LIB="${FLOW_DC_TARGET_LIB:-$DC_TARGET_LIB}"
PT_TARGET_LIB="${FLOW_PT_TARGET_LIB:-$DC_TARGET_LIB}"
GPDK045_TECH_LEF="${GPDK045_TECH_LEF:-/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_tech.lef}"
GPDK045_MACRO_LEF="${GPDK045_MACRO_LEF:-/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_macro.lef}"
GPDK045_QRC="${GPDK045_QRC:-/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/qrc/qx/gpdk045.tch}"
GPDK045_STD_GDS="${GPDK045_STD_GDS:-/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/gds/gsclib045.gds}"
PEGASUS_DRC_RULE="${PEGASUS_DRC_RULE:-/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/pvs/pvlDRC.rul}"

usage() {
  cat <<'EOF'
Usage: ./flows/run_digital_flow.sh <module_name>

Default inputs:
  rtl/<module>.v
  constraints/<module>.sdc
  tb/tb_<module>.v            (optional)

Useful overrides:
  FLOW_RTL=/abs/path/to/top.v
  FLOW_SDC=/abs/path/to/top.sdc
  FLOW_TB=/abs/path/to/tb_top.v
  FLOW_DC_TARGET_LIB=/abs/path/to/dc_mapping.lib
  FLOW_RUN_ROOT=/abs/path/to/run_root
  FLOW_SPEF=/abs/path/to/top.spef
  FLOW_SYNTH_TOOL=auto        (auto: .db -> dc, .lib -> genus)
  FLOW_PT_TARGET_LIB=/abs/path/to/pt_timing.db
  FLOW_ENABLE_POWER_GRID=1     (default: 0; enables addRing + sroute)
  FLOW_ENABLE_FILLERS=1        (default: 0; enables addFiller + ecoRoute)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

TOP="$1"
DEFAULT_RTL="$REPO_ROOT/rtl/$TOP.v"
DEFAULT_SDC="$REPO_ROOT/constraints/$TOP.sdc"
DEFAULT_TB="$REPO_ROOT/tb/tb_$TOP.v"
EXAMPLE_RTL="$REPO_ROOT/examples/$TOP/$TOP.v"
EXAMPLE_SDC="$REPO_ROOT/examples/$TOP/$TOP.sdc"

if [[ -f "$DEFAULT_RTL" ]]; then
  RTL_DEFAULT_VALUE="$DEFAULT_RTL"
else
  RTL_DEFAULT_VALUE="$EXAMPLE_RTL"
fi

if [[ -f "$DEFAULT_SDC" ]]; then
  SDC_DEFAULT_VALUE="$DEFAULT_SDC"
else
  SDC_DEFAULT_VALUE="$EXAMPLE_SDC"
fi

RTL_FILE="${FLOW_RTL:-$RTL_DEFAULT_VALUE}"
SDC_FILE="${FLOW_SDC:-$SDC_DEFAULT_VALUE}"
TB_FILE="${FLOW_TB:-$DEFAULT_TB}"
RUN_ROOT="${FLOW_RUN_ROOT:-$REPO_ROOT/runs/digital-flow}"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$RUN_ROOT/${RUN_ID}_${TOP}"
LIBCACHE_DIR="${FLOW_LIBCACHE_DIR:-$RUN_ROOT/libcache}"

SUMMARY_FILE="$RUN_DIR/summary.txt"
STAGE_FILE="$RUN_DIR/stages.tsv"
RUN_LOG="$RUN_DIR/run.log"

SIM_DIR="$RUN_DIR/rtl-sim"
DC_DIR="$RUN_DIR/dc"
INNOVUS_DIR="$RUN_DIR/innovus"
PT_DIR="$RUN_DIR/primetime"
PEG_DIR="$RUN_DIR/pegasus"
SCRIPTS_DIR="$RUN_DIR/scripts"
RTL_DIR="$(dirname "$RTL_FILE")"
TB_DIR="$(dirname "$TB_FILE")"
PT_EFFECTIVE_LIB="$PT_TARGET_LIB"
PT_SDC_FILE="$PT_DIR/${TOP}_pt.sdc"

FLOW_STATUS="FAILED"
SYNTH_TOOL="${FLOW_SYNTH_TOOL:-auto}"
case "$SYNTH_TOOL" in
  auto)
    if [[ "$DC_SYNTH_LIB" == *.lib ]]; then
      SYNTH_TOOL="genus"
    else
      SYNTH_TOOL="dc"
    fi
    ;;
  dc|genus)
    ;;
  *)
    echo "Unsupported FLOW_SYNTH_TOOL: $SYNTH_TOOL" >&2
    exit 2
    ;;
esac

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 2
  fi
}

record_stage() {
  printf "%s\t%s\t%s\n" "$1" "$2" "$3" >> "$STAGE_FILE"
}

parse_lib_name() {
  sed -n 's/^[[:space:]]*library[[:space:]]*(\([[:alnum:]_][[:alnum:]_]*\)).*/\1/p' "$1" | head -n 1
}

compile_lib_to_db() {
  local source_lib="$1"
  local compiled_db="$2"
  local compile_tcl="$3"
  local compile_log="$4"
  local lib_name

  lib_name="$(parse_lib_name "$source_lib")"
  if [[ -z "$lib_name" ]]; then
    return 1
  fi

  cat > "$compile_tcl" <<EOF
read_lib "$source_lib"
write_lib -output "$compiled_db" "$lib_name"
exit
EOF

  csh -fc "source '$PT_SETUP'; '$LC_BIN' -f '$compile_tcl' -no_init" >"$compile_log" 2>&1
}

build_ptsafe_lib() {
  local source_lib="$1"
  local safe_lib="$2"

  awk '
BEGIN { skip = 0; depth = 0 }
{
  line = $0
  if (!skip && match(line, /^[[:space:]]*cell[[:space:]]*\(([[:alnum:]_]+)\)[[:space:]]*\{/, m)) {
    cell = m[1]
    if (cell ~ /^TLAT(NSR|SR)X(1|2|4|L)$/) {
      open_count = gsub(/\{/, "{", line)
      close_count = gsub(/\}/, "}", line)
      skip = 1
      depth = open_count - close_count
      next
    }
  }

  if (skip) {
    open_count = gsub(/\{/, "{", line)
    close_count = gsub(/\}/, "}", line)
    depth += open_count - close_count
    if (depth <= 0) {
      skip = 0
      depth = 0
    }
    next
  }

  print $0
}
' "$source_lib" > "$safe_lib"
}

resolve_pt_library() {
  local requested_lib="$1"
  local lib_base
  local compiled_db
  local compile_tcl
  local compile_log
  local safe_lib

  if [[ "$requested_lib" == *.db ]]; then
    printf '%s\n' "$requested_lib"
    return 0
  fi

  mkdir -p "$LIBCACHE_DIR"
  lib_base="$(basename "${requested_lib%.lib}")"
  compiled_db="$LIBCACHE_DIR/${lib_base}.db"
  compile_tcl="$LIBCACHE_DIR/${lib_base}.lc.tcl"
  compile_log="$LIBCACHE_DIR/${lib_base}.lc.log"

  if [[ -f "$compiled_db" && ! "$requested_lib" -nt "$compiled_db" ]]; then
    echo "Using cached PrimeTime DB library: $compiled_db" >&2
    printf '%s\n' "$compiled_db"
    return 0
  fi

  if [[ -x "$LC_BIN" ]] && compile_lib_to_db "$requested_lib" "$compiled_db" "$compile_tcl" "$compile_log"; then
    if [[ -f "$compiled_db" ]]; then
      echo "Compiled PrimeTime DB library: $compiled_db" >&2
      printf '%s\n' "$compiled_db"
      return 0
    fi
  fi

  if [[ -f "$compiled_db" ]]; then
    echo "WARN: Library Compiler could not refresh $compiled_db; reusing stale cache." >&2
    printf '%s\n' "$compiled_db"
    return 0
  fi

  safe_lib="$LIBCACHE_DIR/${lib_base}_ptsafe.lib"
  if [[ ! -f "$safe_lib" || "$requested_lib" -nt "$safe_lib" ]]; then
    build_ptsafe_lib "$requested_lib" "$safe_lib"
  fi
  echo "WARN: Library Compiler unavailable or failed; using PT-safe Liberty fallback $safe_lib" >&2
  printf '%s\n' "$safe_lib"
}

sanitize_sdc_for_pt() {
  local source_sdc="$1"
  local pt_sdc="$2"

  sed '/^[[:space:]]*current_design[[:space:]].*$/d' "$source_sdc" > "$pt_sdc"
}

finalize_summary() {
  {
    echo "module=$TOP"
    echo "status=$FLOW_STATUS"
    echo "run_dir=$RUN_DIR"
    echo "rtl=$RTL_FILE"
    echo "sdc=$SDC_FILE"
    echo "synth_tool=$SYNTH_TOOL"
    echo "dc_synth_lib=$DC_SYNTH_LIB"
    echo "timing_lib=$DC_TARGET_LIB"
    echo "pt_requested_lib=$PT_TARGET_LIB"
    echo "pt_target_lib=$PT_EFFECTIVE_LIB"
    echo "pt_sdc=$PT_SDC_FILE"
    if [[ -f "$TB_FILE" ]]; then
      echo "tb=$TB_FILE"
    else
      echo "tb=<missing>"
    fi
    echo "dc_mapped=$DC_DIR/out/${TOP}_mapped.v"
    echo "innovus_def=$INNOVUS_DIR/out/${TOP}.def"
    echo "innovus_postroute=$INNOVUS_DIR/out/${TOP}_postroute.v"
    echo "innovus_gds=$INNOVUS_DIR/out/${TOP}.gds"
    echo "primetime_setup=$PT_DIR/reports/${TOP}_setup.rpt"
    echo "primetime_hold=$PT_DIR/reports/${TOP}_hold.rpt"
    echo "primetime_constraints=$PT_DIR/reports/${TOP}_constraints.rpt"
    echo "pegasus_db=$PEG_DIR/${TOP}.db"
    echo
    echo "stage	status	detail"
    cat "$STAGE_FILE"
  } > "$SUMMARY_FILE"
}

trap finalize_summary EXIT

mkdir -p "$RUN_DIR" "$SIM_DIR" "$DC_DIR" "$INNOVUS_DIR" "$PT_DIR" "$PEG_DIR" "$SCRIPTS_DIR"
: > "$STAGE_FILE"
exec > >(tee -a "$RUN_LOG") 2>&1

echo "run_dir=$RUN_DIR"
echo "top=$TOP"

require_file "$RTL_FILE"
require_file "$SDC_FILE"
require_file "$CADENCE_SETUP"
require_file "$PT_SETUP"
require_file "$DC_TARGET_LIB"
require_file "$DC_SYNTH_LIB"
require_file "$PT_TARGET_LIB"
require_file "$GPDK045_TECH_LEF"
require_file "$GPDK045_MACRO_LEF"
require_file "$GPDK045_QRC"
require_file "$GPDK045_STD_GDS"
require_file "$PEGASUS_DRC_RULE"
if [[ "$SYNTH_TOOL" == "dc" ]]; then
  require_file "$DC_SETUP"
else
  require_file "$GENUS_SETUP"
  require_file "$GENUS_BIN"
fi

write_dc_tcl() {
  cat > "$SCRIPTS_DIR/dc_synth.tcl" <<'EOF'
set TOP $::env(FLOW_TOP)
set WORK_DIR $::env(FLOW_DC_DIR)
set RTL_FILE $::env(FLOW_RTL_FILE)
set SDC_FILE $::env(FLOW_SDC_FILE)
set TARGET_LIB $::env(FLOW_DC_TARGET_LIB)

file mkdir $WORK_DIR
file mkdir "$WORK_DIR/work"
file mkdir "$WORK_DIR/reports"
file mkdir "$WORK_DIR/out"

set_app_var search_path [list "." [file dirname $TARGET_LIB] [file dirname $RTL_FILE]]
set_app_var target_library [list $TARGET_LIB]
set_app_var link_library [concat "*" $target_library]
set_app_var synthetic_library [list dw_foundation.sldb]

define_design_lib WORK -path "$WORK_DIR/work"

analyze -format verilog $RTL_FILE
elaborate $TOP
current_design $TOP
link

source $SDC_FILE
set_fix_multiple_port_nets -all -buffer_constants
compile

report_qor > "$WORK_DIR/reports/${TOP}_qor.rpt"
report_area -hierarchy > "$WORK_DIR/reports/${TOP}_area.rpt"
report_timing -max_paths 20 > "$WORK_DIR/reports/${TOP}_timing.rpt"

write -hierarchy -format verilog -output "$WORK_DIR/out/${TOP}_mapped.v"
write_file -format ddc -hierarchy -output "$WORK_DIR/out/${TOP}.ddc"
write_sdc "$WORK_DIR/out/${TOP}.sdc"
exit
EOF
}

write_genus_tcl() {
  cat > "$SCRIPTS_DIR/genus_synth.tcl" <<'EOF'
set TOP $::env(FLOW_TOP)
set WORK_DIR $::env(FLOW_DC_DIR)
set RTL_FILE $::env(FLOW_RTL_FILE)
set SDC_FILE $::env(FLOW_SDC_FILE)
set TARGET_LIB $::env(FLOW_DC_TARGET_LIB)

file mkdir $WORK_DIR
file mkdir "$WORK_DIR/reports"
file mkdir "$WORK_DIR/out"

read_libs $TARGET_LIB
read_hdl -language v2001 $RTL_FILE
elaborate $TOP
read_sdc $SDC_FILE
syn_generic
syn_map

report_area > "$WORK_DIR/reports/${TOP}_area.rpt"
report_timing -max_paths 20 > "$WORK_DIR/reports/${TOP}_timing.rpt"
report_power > "$WORK_DIR/reports/${TOP}_power.rpt"

write_netlist > "$WORK_DIR/out/${TOP}_mapped.v"
write_sdc > "$WORK_DIR/out/${TOP}.sdc"
quit
EOF
}

write_innovus_tcl() {
  cat > "$SCRIPTS_DIR/innovus_pnr.tcl" <<'EOF'
set TOP $::env(FLOW_TOP)
set WORK_DIR $::env(FLOW_INNOVUS_DIR)
set NETLIST $::env(FLOW_NETLIST_FILE)
set SDC_FILE $::env(FLOW_PNR_SDC_FILE)
set TARGET_LIB $::env(DC_TARGET_LIB)
set TECH_LEF $::env(GPDK045_TECH_LEF)
set MACRO_LEF $::env(GPDK045_MACRO_LEF)
set QRC_FILE $::env(GPDK045_QRC)
set STD_GDS $::env(GPDK045_STD_GDS)
set ENABLE_POWER_GRID 0
if {[info exists ::env(FLOW_ENABLE_POWER_GRID)]} {
    set ENABLE_POWER_GRID $::env(FLOW_ENABLE_POWER_GRID)
}
set ENABLE_FILLERS 0
if {[info exists ::env(FLOW_ENABLE_FILLERS)]} {
    set ENABLE_FILLERS $::env(FLOW_ENABLE_FILLERS)
}

proc log_optional {message} {
    puts "FLOW_NOTE: $message"
}

proc run_optional {label script} {
    if {[catch {uplevel 1 $script} err opts]} {
        log_optional "$label skipped: $err"
        return 0
    }
    log_optional "$label complete"
    return 1
}

file mkdir $WORK_DIR
file mkdir "$WORK_DIR/reports"
file mkdir "$WORK_DIR/out"

if {![file exists $NETLIST]} {
    puts "ERROR: Netlist does not exist: $NETLIST"
    exit 3
}

set MMMC_FILE "$WORK_DIR/mmmc.tcl"
set m [open $MMMC_FILE w]
puts $m "create_library_set -name LIBSET -timing [list $TARGET_LIB]"
puts $m "create_rc_corner -name RC -qx_tech_file $QRC_FILE"
puts $m "create_delay_corner -name DELAY -library_set LIBSET -rc_corner RC"
puts $m "create_constraint_mode -name CONSTR -sdc_files [list $SDC_FILE]"
puts $m "create_analysis_view -name VIEW -constraint_mode CONSTR -delay_corner DELAY"
puts $m "set_analysis_view -setup [list VIEW] -hold [list VIEW]"
close $m

set init_design_settop 1
set init_verilog $NETLIST
set init_top_cell $TOP
set init_lef_file "$TECH_LEF $MACRO_LEF"
set init_mmmc_file $MMMC_FILE
set init_pwr_net VDD
set init_gnd_net VSS

init_design
clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -all
globalNetConnect VSS -type pgpin -pin VSS -all
applyGlobalNets

floorPlan -site CoreSite -r 1.0 0.70 10 10 10 10
log_optional "dedicated endcap cells not present in gsclib045 base library; skipping addEndCap"
log_optional "well taps unavailable in gsclib045 base library; skipping addWellTap"
if {$ENABLE_POWER_GRID eq "1"} {
    run_optional "core ring" {
        addRing \
            -nets {VDD VSS} \
            -type core_rings \
            -follow core \
            -layer {top Metal6 bottom Metal6 left Metal5 right Metal5} \
            -width 0.8 \
            -spacing 0.8 \
            -offset 0.8
    }
} else {
    log_optional "power-grid insertion disabled; set FLOW_ENABLE_POWER_GRID=1 to enable addRing + sroute"
}
placeDesign
if {$ENABLE_POWER_GRID eq "1"} {
    run_optional "power sroute" {
        sroute \
            -nets {VDD VSS} \
            -connect {corePin floatingStripe} \
            -allowJogging true \
            -allowLayerChange true
    }
}
routeDesign
if {$ENABLE_FILLERS eq "1"} {
    set filler_inserted [run_optional "filler insertion" {
        addFiller -cell {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} -prefix FILL
    }]
    if {$filler_inserted} {
        run_optional "eco route after filler insertion" {
            ecoRoute -target
        }
    }
} else {
    log_optional "filler insertion disabled; set FLOW_ENABLE_FILLERS=1 to enable addFiller + ecoRoute"
}

report_area > "$WORK_DIR/reports/${TOP}_area.rpt"
report_timing -max_paths 20 > "$WORK_DIR/reports/${TOP}_timing.rpt"
report_power > "$WORK_DIR/reports/${TOP}_power.rpt"

defOut "$WORK_DIR/out/${TOP}.def"
saveNetlist "$WORK_DIR/out/${TOP}_postroute.v"

set gds_out "$WORK_DIR/out/${TOP}.gds"
if {[catch {streamOut $gds_out -merge [list $STD_GDS] -units 2000 -mode ALL} err]} {
    puts "WARN: streamOut failed: $err"
    set sf [open "$WORK_DIR/reports/${TOP}_streamout.warn" w]
    puts $sf $err
    close $sf
    exit 4
}

exit
EOF
}

write_pt_tcl() {
  cat > "$SCRIPTS_DIR/primetime.tcl" <<'EOF'
set TOP $::env(FLOW_TOP)
set WORK_DIR $::env(FLOW_PT_DIR)
set NETLIST $::env(FLOW_POSTROUTE_NETLIST)
set SDC_FILE $::env(FLOW_PT_SDC_FILE)
set LIB $::env(FLOW_PT_TARGET_LIB)

file mkdir $WORK_DIR
file mkdir "$WORK_DIR/reports"

set search_path [list [file dirname $NETLIST] [file dirname $LIB]]
if {[string match "*.db" $LIB]} {
    set target_library [list $LIB]
    set link_path [concat "*" $target_library]
} else {
    read_lib $LIB
    set target_library [get_object_name [get_libs *]]
    set link_path [concat "*" $target_library]
}

read_verilog $NETLIST
link_design $TOP
read_sdc $SDC_FILE

if {[info exists ::env(FLOW_SPEF_FILE)] && [file exists $::env(FLOW_SPEF_FILE)]} {
    read_parasitics -format spef $::env(FLOW_SPEF_FILE)
}

report_timing -delay max -slack_lesser_than 1000 -max_paths 20 > "$WORK_DIR/reports/${TOP}_setup.rpt"
report_timing -delay min -slack_lesser_than 1000 -max_paths 20 > "$WORK_DIR/reports/${TOP}_hold.rpt"
report_constraint -all_violators > "$WORK_DIR/reports/${TOP}_constraints.rpt"
exit
EOF
}

write_pegasus_rule() {
  local gds_file="$1"
  local db_file="$2"
  sed \
    -e "s|layout_path \"CELLNAME.gds\" gdsii;|layout_path \"$gds_file\" gdsii;|" \
    -e "s|layout_primary \"CELLNAME\";|layout_primary \"$TOP\";|" \
    -e "s|results_db -drc \"CELLNAME.db\" -ascii;|results_db -drc \"$db_file\" -ascii;|" \
    "$PEGASUS_DRC_RULE" > "$SCRIPTS_DIR/${TOP}_pegasus_drc.rul"
}

write_dc_tcl
write_genus_tcl
write_innovus_tcl
write_pt_tcl

if [[ -f "$TB_FILE" ]]; then
  echo "[rtl_sim] running Xcelium"
  if (
    cd "$SIM_DIR"
    bash -lc "source '$CADENCE_SETUP' >/dev/null && '$XRUN_BIN' -clean -64bit -access +rwc -timescale 1ns/1ps -incdir '$REPO_ROOT' -incdir '$REPO_ROOT/rtl' -incdir '$REPO_ROOT/tb' -incdir '$RTL_DIR' -incdir '$TB_DIR' -l '$SIM_DIR/xrun.log' '$RTL_FILE' '$TB_FILE'"
  ); then
    require_file "$SIM_DIR/xrun.log"
    record_stage "rtl_sim" "PASS" "log=$SIM_DIR/xrun.log"
  else
    record_stage "rtl_sim" "FAIL" "log=$SIM_DIR/xrun.log"
    exit 1
  fi
else
  echo "[rtl_sim] skipped; missing testbench $TB_FILE"
  record_stage "rtl_sim" "SKIP" "missing_tb=$TB_FILE"
fi

echo "[synth] running $SYNTH_TOOL synthesis"
if [[ "$SYNTH_TOOL" == "dc" ]]; then
  if csh -fc "setenv FLOW_TOP '$TOP'; setenv FLOW_DC_DIR '$DC_DIR'; setenv FLOW_RTL_FILE '$RTL_FILE'; setenv FLOW_SDC_FILE '$SDC_FILE'; setenv FLOW_DC_TARGET_LIB '$DC_SYNTH_LIB'; source '$DC_SETUP'; '$DC_BIN' -f '$SCRIPTS_DIR/dc_synth.tcl'" >"$DC_DIR/dc_shell.log" 2>&1; then
    require_file "$DC_DIR/out/${TOP}_mapped.v"
    require_file "$DC_DIR/out/${TOP}.sdc"
    record_stage "synth" "PASS" "tool=dc netlist=$DC_DIR/out/${TOP}_mapped.v"
  else
    record_stage "synth" "FAIL" "tool=dc log=$DC_DIR/dc_shell.log"
    exit 1
  fi
  PNR_SDC_FILE="$DC_DIR/out/${TOP}.sdc"
else
  if csh -fc "setenv FLOW_TOP '$TOP'; setenv FLOW_DC_DIR '$DC_DIR'; setenv FLOW_RTL_FILE '$RTL_FILE'; setenv FLOW_SDC_FILE '$SDC_FILE'; setenv FLOW_DC_TARGET_LIB '$DC_SYNTH_LIB'; source '$GENUS_SETUP'; '$GENUS_BIN' -files '$SCRIPTS_DIR/genus_synth.tcl' -no_gui -batch -log '$DC_DIR/genus'" >"$DC_DIR/genus_shell.log" 2>&1; then
    require_file "$DC_DIR/out/${TOP}_mapped.v"
    require_file "$DC_DIR/out/${TOP}.sdc"
    record_stage "synth" "PASS" "tool=genus netlist=$DC_DIR/out/${TOP}_mapped.v"
  else
    record_stage "synth" "FAIL" "tool=genus log=$DC_DIR/genus_shell.log"
    exit 1
  fi
  PNR_SDC_FILE="$DC_DIR/out/${TOP}.sdc"
fi

POSTROUTE_NETLIST="$INNOVUS_DIR/out/${TOP}_postroute.v"
GDS_FILE="$INNOVUS_DIR/out/${TOP}.gds"
PEGASUS_DB="$PEG_DIR/${TOP}.db"

echo "[innovus] running place and route"
if bash -lc "source '$CADENCE_SETUP' >/dev/null && export FLOW_TOP='$TOP' FLOW_INNOVUS_DIR='$INNOVUS_DIR' FLOW_NETLIST_FILE='$DC_DIR/out/${TOP}_mapped.v' FLOW_PNR_SDC_FILE='$PNR_SDC_FILE' DC_TARGET_LIB='$DC_TARGET_LIB' GPDK045_TECH_LEF='$GPDK045_TECH_LEF' GPDK045_MACRO_LEF='$GPDK045_MACRO_LEF' GPDK045_QRC='$GPDK045_QRC' GPDK045_STD_GDS='$GPDK045_STD_GDS' FLOW_ENABLE_POWER_GRID='${FLOW_ENABLE_POWER_GRID:-0}' FLOW_ENABLE_FILLERS='${FLOW_ENABLE_FILLERS:-0}' && '$INNOVUS_BIN' -no_gui -overwrite -files '$SCRIPTS_DIR/innovus_pnr.tcl'" >"$INNOVUS_DIR/innovus.log" 2>&1; then
  require_file "$INNOVUS_DIR/out/${TOP}.def"
  require_file "$POSTROUTE_NETLIST"
  require_file "$GDS_FILE"
  record_stage "innovus" "PASS" "gds=$GDS_FILE"
else
  record_stage "innovus" "FAIL" "log=$INNOVUS_DIR/innovus.log"
  exit 1
fi

echo "[primetime] running timing checks"
if [[ -n "${FLOW_SPEF:-}" ]]; then
  require_file "$FLOW_SPEF"
fi
PT_EFFECTIVE_LIB="$(resolve_pt_library "$PT_TARGET_LIB")"
require_file "$PT_EFFECTIVE_LIB"
sanitize_sdc_for_pt "$PNR_SDC_FILE" "$PT_SDC_FILE"
if FLOW_TOP="$TOP" \
  FLOW_PT_DIR="$PT_DIR" \
  FLOW_POSTROUTE_NETLIST="$POSTROUTE_NETLIST" \
  FLOW_PT_SDC_FILE="$PT_SDC_FILE" \
  FLOW_PT_TARGET_LIB="$PT_EFFECTIVE_LIB" \
  FLOW_SPEF_FILE="${FLOW_SPEF:-}" \
  csh -fc "source '$PT_SETUP'; '$PT_BIN' -f '$SCRIPTS_DIR/primetime.tcl' -no_init" >"$PT_DIR/pt_shell.log" 2>&1; then
  require_file "$PT_DIR/reports/${TOP}_setup.rpt"
  require_file "$PT_DIR/reports/${TOP}_hold.rpt"
  require_file "$PT_DIR/reports/${TOP}_constraints.rpt"
  if grep -q "Error:" "$PT_DIR/pt_shell.log"; then
    record_stage "primetime" "FAIL" "errors_in_log=$PT_DIR/pt_shell.log"
    exit 1
  fi
  if grep -q "No constrained paths" "$PT_DIR/reports/${TOP}_setup.rpt" || grep -q "No constrained paths" "$PT_DIR/reports/${TOP}_hold.rpt"; then
    record_stage "primetime" "FAIL" "unconstrained_paths setup=$PT_DIR/reports/${TOP}_setup.rpt"
    exit 1
  fi
  if ! grep -Eq 'slack \((MET|VIOLATED)\)' "$PT_DIR/reports/${TOP}_setup.rpt" || ! grep -Eq 'slack \((MET|VIOLATED)\)' "$PT_DIR/reports/${TOP}_hold.rpt"; then
    record_stage "primetime" "FAIL" "missing_slack_values setup=$PT_DIR/reports/${TOP}_setup.rpt"
    exit 1
  fi
  record_stage "primetime" "PASS" "setup=$PT_DIR/reports/${TOP}_setup.rpt lib=$PT_EFFECTIVE_LIB"
else
  record_stage "primetime" "FAIL" "log=$PT_DIR/pt_shell.log"
  exit 1
fi

echo "[pegasus] running DRC"
write_pegasus_rule "$GDS_FILE" "$PEGASUS_DB"
if bash -lc "source '$CADENCE_SETUP' >/dev/null && export CDS_SKIP_OS_CHECK_ON_STARTUP=1 && '$PEGASUS_BIN' -drc -log '$PEG_DIR/${TOP}_drc.log' -run_dir '$PEG_DIR/run' '$SCRIPTS_DIR/${TOP}_pegasus_drc.rul'" >"$PEG_DIR/pegasus.stdout.log" 2>&1; then
  require_file "$PEG_DIR/${TOP}_drc.log"
  require_file "$PEGASUS_DB"
  if grep -Eq 'completed with [1-9][0-9]* violations' "$PEG_DIR/${TOP}_drc.log"; then
    record_stage "pegasus" "FAIL" "violations_found log=$PEG_DIR/${TOP}_drc.log"
    exit 1
  fi
  record_stage "pegasus" "PASS" "db=$PEGASUS_DB"
else
  record_stage "pegasus" "FAIL" "log=$PEG_DIR/${TOP}_drc.log"
  exit 1
fi

FLOW_STATUS="PASS"
echo "Flow completed successfully."
echo "Summary: $SUMMARY_FILE"
