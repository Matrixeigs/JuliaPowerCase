# ═══════════════════════════════════════════════════════════════════════════════
# Hybrid AC/DC Test Cases
# ═══════════════════════════════════════════════════════════════════════════════

"""
    case_hybrid_5ac3dc(; T=Float64) -> HybridPowerCaseData{T}

Small hybrid AC/DC test system: 5 AC buses + 3 DC buses + 2 VSC converters.
Useful for unit testing and algorithm development.
"""
function case_hybrid_5ac3dc(; T::Type{<:Real}=Float64)
    h = HybridPowerCaseData{T}()
    h.name = "Hybrid 5-AC/3-DC test system"
    h.base_mva = T(100)

    # ── AC sub-system ─────────────────────────────────────────────────────
    ac = PowerCaseData{AC, T}()
    ac.base_mva = T(100)

    ac.bus = ComponentMatrix{BusSchema, T}(T[
        1  3  0.0   0.0  0 0 1 1.06  0.0 230 1 1.06 0.94  0 0 0 0 0 0 0 1;
        2  2  20.0  10.0 0 0 1 1.04  0.0 230 1 1.06 0.94  0 0 0 0 0 0 0 1;
        3  1  45.0  15.0 0 0 1 1.00  0.0 230 1 1.06 0.94  0 0 0 0 0 0 0 1;
        4  1  40.0  5.0  0 0 1 1.00  0.0 230 1 1.06 0.94  0 0 0 0 0 0 0 1;
        5  1  60.0  10.0 0 0 1 1.00  0.0 230 1 1.06 0.94  0 0 0 0 0 0 0 1;
    ])

    ac.branch = ComponentMatrix{BranchSchema, T}(T[
        1 1 2 0.02 0.06  0.06 250 250 250 0 0 1 -360 360  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
        2 1 3 0.08 0.24  0.05 250 250 250 0 0 1 -360 360  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
        3 2 3 0.06 0.18  0.04 250 250 250 0 0 1 -360 360  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
        4 3 4 0.06 0.18  0.04 250 250 250 0 0 1 -360 360  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
        5 4 5 0.04 0.12  0.03 250 250 250 0 0 1 -360 360  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
    ])

    gen_data = zeros(T, 2, ncols(GenSchema))
    # INDEX GEN_BUS PG QG QMAX QMIN VG MBASE STATUS PMAX PMIN
    gen_data[1, 1] = 1; gen_data[1, 2] = 1; gen_data[1, 3] = 130; gen_data[1, 5] = 100; gen_data[1, 6] = -100
    gen_data[1, 7] = 1.06; gen_data[1, 8] = 100; gen_data[1, 9] = 1; gen_data[1, 10] = 200
    gen_data[2, 1] = 2; gen_data[2, 2] = 2; gen_data[2, 3] = 50;  gen_data[2, 5] = 50;  gen_data[2, 6] = -50
    gen_data[2, 7] = 1.04; gen_data[2, 8] = 100; gen_data[2, 9] = 1; gen_data[2, 10] = 100
    ac.gen = ComponentMatrix{GenSchema, T}(gen_data)
    h.ac = ac

    # ── DC sub-system ─────────────────────────────────────────────────────
    # DC bus: [bus_id, type, pd, vdc, vmax, vmin, area, zone]
    h.dc_bus = ComponentMatrix{DCBusSchema, T}(T[
        101  2  0.0  1.0  1.1  0.9  1  1;
        102  1  20.0 1.0  1.1  0.9  1  1;
        103  1  15.0 1.0  1.1  0.9  1  1;
    ])

    # DC branch: [f_bus, t_bus, r, l, c, rate_a, rate_b, rate_c, status, length, type]
    h.dc_branch = ComponentMatrix{DCBranchSchema, T}(T[
        101 102 0.01 0.0 0.0 200 200 200 1 10.0 1;
        102 103 0.02 0.0 0.0 200 200 200 1 15.0 1;
    ])

    # VSC converters linking AC ↔ DC
    # VSCSchema: [BUS_AC, BUS_DC, P_MW, Q_MVAR, VM_AC_PU, VM_DC_PU, LOSS_PERCENT, LOSS_MW, PMAX, PMIN, QMAX, QMIN, CONTROL_MODE, DROOP_KV, IN_SERVICE, CONTROLLABLE]
    h.vsc = ComponentMatrix{VSCSchema, T}(T[
        3   101  30.0  10.0  1.0  1.0  1.0  0.0  100.0  -100.0  50.0  -50.0  1  0.05  1  1;
        5   103  15.0   5.0  1.0  1.0  1.0  0.0  100.0  -100.0  50.0  -50.0  1  0.05  1  1;
    ])

    return h
end
