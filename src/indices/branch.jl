# ═══════════════════════════════════════════════════════════════════════════════
# BranchIdx — Branch column schemas (AC & DC)
# ═══════════════════════════════════════════════════════════════════════════════

# ── AC Branch: 38 columns (INDEX + MATPOWER-compatible) ──────────────────────
@define_schema BranchSchema INDEX  F_BUS  T_BUS  BR_R  BR_X  BR_B  RATE_A  RATE_B  RATE_C  TAP  SHIFT  STATUS  ANGMIN  ANGMAX  DICTKEY  MAX_I  SN_MVA  PF  QF  PT  QT  MU_SF  MU_ST  MU_ANGMIN  MU_ANGMAX  LAMBDA  SW_TIME  RP_TIME  BR_TYPE  BR_AREA  BR_R0  BR_X0  BR_B0  BR_HV_BASEKV  BR_LV_BASEKV  BR_VN_HV  BR_VN_LV  BR_SN_MVA

# ── DC Branch ────────────────────────────────────────────────────────────────
@define_schema DCBranchSchema F_BUS  T_BUS  BR_R  BR_L  BR_C  RATE_A  RATE_B  RATE_C  BR_STATUS  LENGTH_KM  MAX_I

# ── Transformer (ETAP short-circuit generic) ─────────────────────────────────
@define_schema TransformerSchema  F_BUS  T_BUS  BR_R  BR_X  BR_B  RATE_A  TAP  SHIFT  BR_STATUS  ANGMIN  ANGMAX  VN_HV  VN_LV  HV_BASEKV  LV_BASEKV  SN_MVA  BR_R0  BR_X0  BR_B0

# ── 2-Winding Transformer ────────────────────────────────────────────────────
@define_schema Trafo2WSchema  HV_BUS  LV_BUS  SN_MVA  VN_HV_KV  VN_LV_KV  VK_PERCENT  VKR_PERCENT  PFE_KW  I0_PERCENT  SHIFT_DEG  TAP_SIDE  TAP_POS  TAP_MIN  TAP_MAX  TAP_STEP_PERCENT  TAP_NEUTRAL  BR_STATUS  Z0_PERCENT  X0_R0

# ── 3-Winding Transformer ────────────────────────────────────────────────────
@define_schema Trafo3WSchema  HV_BUS  MV_BUS  LV_BUS  SN_HV_MVA  SN_MV_MVA  SN_LV_MVA  VN_HV_KV  VN_MV_KV  VN_LV_KV  VK_HV_PERCENT  VK_MV_PERCENT  VK_LV_PERCENT  VKR_HV_PERCENT  VKR_MV_PERCENT  VKR_LV_PERCENT  PFE_KW  I0_PERCENT  SHIFT_MV_DEG  SHIFT_LV_DEG  BR_STATUS
