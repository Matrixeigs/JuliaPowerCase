# ═══════════════════════════════════════════════════════════════════════════════
# Remaining Index schemas — Storage, Switch, Shunt, SC, etc.
# ═══════════════════════════════════════════════════════════════════════════════

# ── Storage (ESS): 13 columns (INDEX added) ─────────────────────────────────
@define_schema StorageSchema  INDEX  STOR_BUS  STOR_STATUS  STOR_P  STOR_EMAX  STOR_PMAX  STOR_PMIN  STOR_ETA_CH  STOR_ETA_DIS  STOR_SOC_MIN  STOR_SOC_MAX  STOR_SOC_INIT  STOR_E_MWH

# ── Battery AC (BESS with integrated converter) ─────────────────────────────
@define_schema BattACSchema  BUS  STATUS  P_CHARGE  P_DISCHARGE  Q  SOC  SOC_MIN  SOC_MAX  P_MAX  EFF_CHARGE  EFF_DISCHARGE  COST_DISCHARGE

# ── Battery DC (DC-side only) ────────────────────────────────────────────────
@define_schema BattDCSchema  BUS  STATUS  P_CHARGE  P_DISCHARGE  SOC  SOC_MIN  SOC_MAX  P_MAX  EFF_CHARGE  EFF_DISCHARGE  COST_DISCHARGE

# ── Storage ETAP model ───────────────────────────────────────────────────────
@define_schema StorageETAPSchema  BUS  RA  CELL  STR  PACKAGE  VOC  IN_SERVICE  TYPE  CONTROLLABLE

# ── Switch (INDEX added) ─────────────────────────────────────────────────────
@define_schema SwitchSchema  INDEX  BUS_FROM  BUS_TO  ELEMENT_TYPE  ELEMENT_ID  CLOSED  SWITCH_TYPE  Z_OHM  IN_SERVICE

# ── High-Voltage Circuit Breaker ─────────────────────────────────────────────
@define_schema HVCBSchema  ID  FROM_ELEMENT  TO_ELEMENT  INSERVICE  STATUS

# ── Shunt ────────────────────────────────────────────────────────────────────
@define_schema ShuntSchema  BUS  GS_MW  BS_MVAR  STEP  MAX_STEP  IN_SERVICE

# ── Microgrid ────────────────────────────────────────────────────────────────
@define_schema MicrogridSchema  ID  CAPACITY  PEAK_LOAD  DURATION  AREA

# ── Electric Vehicle ─────────────────────────────────────────────────────────
@define_schema EVSchema  ID  CAPACITY  FLEX_CAPACITY  AREA

# ── Short-Circuit Result ─────────────────────────────────────────────────────
@define_schema SCResultSchema  BUS  IKSS  IP  IB  IK

# ── Fault Specification ──────────────────────────────────────────────────────
@define_schema FaultSchema  TYPE  BUS  IMPEDANCE  CALC_TYPE  BREAKING_TIME  TOPOLOGY  KAPPA_METHOD

# ── Three-Phase Result ───────────────────────────────────────────────────────
@define_schema ThreePhaseResultSchema  BUS  VM_A  VM_B  VM_C  VA_A  VA_B  VA_C  UNBALANCED  PA_MW  PB_MW  PC_MW  QA_MVAR  QB_MVAR  QC_MVAR
