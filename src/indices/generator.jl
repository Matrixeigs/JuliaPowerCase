# ═══════════════════════════════════════════════════════════════════════════════
# GenIdx — Generator column schemas
# ═══════════════════════════════════════════════════════════════════════════════

# ── Gen: 48 columns (INDEX + MATPOWER-compatible + sequence network params) ──
@define_schema GenSchema    INDEX  GEN_BUS  PG  QG  QMAX  QMIN  VG  MBASE  GEN_STATUS  PMAX  PMIN  PC1  PC2  QC1MIN  QC1MAX  QC2MIN  QC2MAX  RAMP_AGC  RAMP_10  RAMP_30  RAMP_Q  APF  MODEL  STARTUP  SHUTDOWN  NCOST  COST  CARBON_EMISSION  MU_PMAX  MU_PMIN  MU_QMAX  MU_QMIN  AREA  VN_KV  XD_SUB  X_R  RA  COS_PHI  XD  XQ  XD_XQ  X0  X0_R0  R0  R1  X1  R2  X2

# ── Generator Cost ───────────────────────────────────────────────────────────
@define_schema GenCostSchema  MODEL  STARTUP  SHUTDOWN  NCOST  COST1  COST2  COST3

# ── Static Generator (PV / Wind / CHP) ── 26 columns for full spec ─────────
@define_schema SgenSchema  ID  BUS  IN_SERVICE  SGEN_TYPE  P_RATED_MW  Q_RATED_MVAR  SN_MVA  P_MW  Q_MVAR  SCALING  PMAX  PMIN  QMAX  QMIN  CONTROLLABLE  V_REF_PU  K_P  K_Q  F_REF_HZ  K_SC  RX  MTBF_H  MTTR_H  T_SCHED_H  CO2_RATE  AREA

# ── External Grid (utility interconnection) ─────────────────────────────────
@define_schema ExtGridSchema  INDEX  BUS  VN_KV  STATUS  IKQ  X_R  R  X  R0  X0

# ── PV Array (DC-side panel model) ──────────────────────────────────────────
@define_schema PVArraySchema  ID  BUS  VOC  VMPP  ISC  IMPP  IRRADIANCE  AREA  IN_SERVICE

# ── AC PV System (panel + inverter) ─────────────────────────────────────────
@define_schema PVACSystemSchema  ID  BUS  VOC  VMPP  ISC  IMPP  IRRADIANCE  INVERTER_EFF  INVERTER_MODE  INVERTER_PAC  INVERTER_QAC  INVERTER_QAC_MAX  INVERTER_QAC_MIN  AREA  IN_SERVICE
