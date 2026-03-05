# ═══════════════════════════════════════════════════════════════════════════════
# BusIdx — Bus column schemas (AC & DC)
# ═══════════════════════════════════════════════════════════════════════════════

# ── AC Bus: 21 columns, MATPOWER-compatible + resilience ─────────────────────
@define_schema BusSchema    I  TYPE  PD  QD  GS  BS  AREA  VM  VA  BASE_KV  ZONE  VMAX  VMIN  CARBON_AREA  CARBON_ZONE  LAM_P  LAM_Q  MU_VMAX  MU_VMIN  PER_CONSUMER  OMEGA

# ── DC Bus: 8 columns for DC network buses ──────────────────────────────────
@define_schema DCBusSchema  I  TYPE  PD  VDC  VMAX  VMIN  AREA  ZONE
