# ═══════════════════════════════════════════════════════════════════════════════
# LoadIdx — Load column schemas
# ═══════════════════════════════════════════════════════════════════════════════

# ── Load: 18 columns, MATPOWER-compatible ────────────────────────────────────
@define_schema LoadSchema   LOAD_I  LOAD_BUS  LOAD_STATUS  LOAD_PD  LOAD_QD  SCALING  Z_PERCENT  I_PERCENT  P_PERCENT  PROFILE  SN_MVA  VN_KV  MOTOR_PERCENT  LRC  X_R  X_SUB  R  X

# ── Flexible Load ────────────────────────────────────────────────────────────
@define_schema FlexLoadSchema  I  CND  STATUS  PD  QD  Z_PERCENT  I_PERCENT  P_PERCENT  PROFILE  FLEX_UP_MW  FLEX_DOWN_MW  FLEX_DURATION_H  CAPACITY_MW  ENERGY_MWH  RESPONSE_TIME_S  RAMP_RATE  AVAILABILITY  CONTROL_AREA  RESOURCE_TYPE  RESOURCE_ID  CAPACITY_SHARE  CONTROL_PRIORITY  RESOURCE_RESPONSE  MAX_DURATION  OPERATOR

# ── Asymmetric Load ──────────────────────────────────────────────────────────
@define_schema AsymLoadSchema  I  CND  STATUS  PD  QD  Z_PERCENT  I_PERCENT  P_PERCENT  PROFILE  PA  QA  PB  QB  PC  QC

# ── Induction Motor (for short-circuit) ──────────────────────────────────────
@define_schema IndMotorSchema  ID  BUS  VN_KV  SN_MVA  X_PU  X_R  R_PU  TDP  LRC  POLES  VM_MAX_PU  VM_MIN_PU  COS_PHI  EFFICIENCY  IN_SERVICE  X0_PU  X0_R0  R0_PU

# ── Motor (ETAP variant) ────────────────────────────────────────────────────
@define_schema MotorSchema  ID  BUS  VN_KV  SN_MVA  X  X_R  R  TDP  LRC  POLES  MAX_VM_PU  MIN_VM_PU  STATUS  COS_PHI  EFFICIENCY  X0  X0_R0  R0
