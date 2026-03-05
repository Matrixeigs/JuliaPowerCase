# ═══════════════════════════════════════════════════════════════════════════════
# ConvIdx — Converter column schemas
# ═══════════════════════════════════════════════════════════════════════════════

# ── VSC Converter (full spec), 33 columns ───────────────────────────────────
@define_schema ConverterSchema  INDEX  ACBUS  DCBUS  INSERVICE  VSC_TYPE  P_RATED_MW  VN_AC_KV  VN_DC_KV  P_AC  Q_AC  VM_AC_PU  VM_DC_PU  PMAX  PMIN  QMAX  QMIN  EFF  LOSS_PERCENT  LOSS_MW  CONTROLLABLE  MODE  P_SET  Q_SET  V_AC_SET  V_DC_SET  K_VDC  K_P  K_Q  V_REF_PU  F_REF_HZ  MTBF_H  MTTR_H  T_SCHED_H

# ── VSC Converter (detailed for OPF) ────────────────────────────────────────
@define_schema VSCSchema  BUS_AC  BUS_DC  P_MW  Q_MVAR  VM_AC_PU  VM_DC_PU  LOSS_PERCENT  LOSS_MW  PMAX  PMIN  QMAX  QMIN  CONTROL_MODE  DROOP_KV  IN_SERVICE  CONTROLLABLE

# ── DCDC Converter (full spec), 24 columns ──────────────────────────────────
@define_schema DCDCSchema  INDEX  BUS_IN  BUS_OUT  INSERVICE  CONTROLLABLE  V_IN_PU  V_OUT_PU  P_IN_MW  P_OUT_MW  P_REF_MW  V_REF_PU  SN_MVA  VN_IN_KV  VN_OUT_KV  EFF  R_EQ_PU  F_SWITCH_KHZ  PMAX  PMIN  MODE  K_DROOP  MTBF_H  MTTR_H  T_SCHED_H

# ── Energy Router (full spec), 22 columns ───────────────────────────────────
@define_schema ERSchema  ID  INSERVICE  ER_TYPE  NUM_PORTS  P_RATED_MW  VN_AC_KV  VN_DC_KV  LOSS_PERCENT  MODE  DISPATCH_STRATEGY  PMAX  PMIN  QMAX  QMIN  VMAX_PU  VMIN_PU  MTBF_H  MTTR_H  T_SCHED_H  INVEST_COST  OP_COST_MWH  MAINT_COST_YR

# ── Energy Router Core ───────────────────────────────────────────────────────
@define_schema EnergyRouterCoreSchema  ID  PRIME_BUS  SECOND_BUS  LOSS_PERCENT  MAX_P_MW  MIN_P_MW  INSERVICE

# ── Energy Router Converter Port ─────────────────────────────────────────────
@define_schema EnergyRouterConvSchema  BUS_AC  BUS_DC  P_MW  Q_MVAR  MAX_P_MW  MIN_P_MW  MAX_Q_MVAR  MIN_Q_MVAR  VM_AC_PU  VM_DC_PU  LOSS_PERCENT  CONTROL_MODE  IN_SERVICE  CORE_IDX  SIDE

# ── Energy Router (multi-port aggregator) ────────────────────────────────────
@define_schema EnergyRouterSchema  ID  PRIME_BUS  SECOND_BUS  LOSS_PERCENT  PMAX  PMIN  IN_SERVICE

# ── Energy Router Port (full spec), 21 columns ───────────────────────────────
@define_schema ERPortSchema  ID  ROUTER_ID  BUS  PORT_TYPE  VN_KV  P_AC_MW  Q_AC_MVAR  V_AC_PU  P_DC_MW  V_DC_PU  PHI_DEG  PMAX  PMIN  QMAX  QMIN  MODE  P_SET  Q_SET  V_SET  INSERVICE  SIDE
