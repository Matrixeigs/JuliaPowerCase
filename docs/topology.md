# Topology Analysis

JuliaPowerCase provides comprehensive topology analysis functions for detecting islands, analyzing connectivity, and extracting subsystems.

---

## Island Detection

### `find_islands`

Detect connected components in AC networks using DFS.

```julia
find_islands(jpc::PowerCaseData{AC}) -> (groups, isolated)
```

**Returns:**
- `groups::Vector{Vector{Int}}` — External bus numbers per island
- `isolated::Vector{Int}` — Isolated bus numbers (no power source)

**Example:**
```julia
jpc = load_matpower("case14.m")

# Disable some branches to create islands
jpc.branch[3, :STATUS] = 0
jpc.branch[4, :STATUS] = 0

groups, isolated = find_islands(jpc)
println("Found $(length(groups)) island(s)")
for (i, group) in enumerate(groups)
    println("  Island $i: buses $(group)")
end
```

### `find_islands_dc`

Detect connected components in DC networks.

```julia
find_islands_dc(dc_bus::ComponentMatrix, dc_branch::ComponentMatrix) -> (groups, isolated)
```

### `find_islands_acdc`

Detect islands in coupled AC/DC systems considering converter links.

```julia
find_islands_acdc(hybrid::HybridPowerCaseData) -> (ac_groups, dc_groups, coupled_groups)
```

**Returns:**
- `ac_groups` — AC-only islands
- `dc_groups` — DC-only islands  
- `coupled_groups` — Islands with AC-DC coupling

---

## Struct-Based Island Detection

### `detect_islands`

Higher-level interface for struct-based systems.

```julia
detect_islands(sys::PowerSystem{AC}) -> Vector{IslandInfo}
detect_islands(hybrid::HybridPowerSystem) -> Vector{IslandInfo}
```

### `IslandInfo`

Information about a detected island.

```julia
struct IslandInfo
    index::Int                    # Island number
    ac_buses::Vector{Int}         # AC bus indices in this island
    dc_buses::Vector{Int}         # DC bus indices in this island
    has_generation::Bool          # Whether island has active generation
    has_reference::Bool           # Whether island has a reference bus
    total_generation_mw::Float64  # Total generation capacity
    total_load_mw::Float64        # Total load demand
end
```

**Example:**
```julia
sys = case14()

# Disable a branch
sys.branches[5].in_service = false

islands = detect_islands(sys)
for island in islands
    println("Island $(island.index):")
    println("  Buses: $(island.ac_buses)")
    println("  Has reference: $(island.has_reference)")
    println("  Gen/Load: $(island.total_generation_mw)/$(island.total_load_mw) MW")
end
```

---

## Island Extraction

### `extract_island_subsystem`

Extract a single island as an independent subsystem.

```julia
extract_island_subsystem(sys::PowerSystem{K}, island::IslandInfo) -> PowerSystem{K}
extract_island_subsystem(jpc::PowerCaseData{K}, bus_indices::Vector{Int}) -> PowerCaseData{K}
```

**Example:**
```julia
sys = case14()

# Detect islands
islands = detect_islands(sys)

# Extract each island
for island in islands
    subsys = extract_island_subsystem(sys, island)
    println("Extracted island with $(nbuses(subsys)) buses")
end
```

### `extract_islands`

Extract all islands as separate subsystems.

```julia
extract_islands(sys::PowerSystem{AC}) -> Vector{PowerSystem{AC}}
extract_islands(hybrid::HybridPowerSystem) -> Vector{HybridPowerSystem}
```

**Example:**
```julia
sys = case14()
sys.branches[5].in_service = false
sys.branches[10].in_service = false

subsystems = extract_islands(sys)
println("Extracted $(length(subsystems)) island subsystems")
```

---

## Graph Analysis

### `adjacency_list`

Build adjacency list from branch connectivity.

```julia
adjacency_list(sys::PowerSystem{K}) -> Vector{Vector{Int}}
adjacency_list(jpc::PowerCaseData{K}) -> Vector{Vector{Int}}
```

**Returns:** Vector where `adj[i]` contains bus indices connected to bus `i`.

**Example:**
```julia
sys = case5()
adj = adjacency_list(sys)

for (i, neighbors) in enumerate(adj)
    println("Bus $i -> $(neighbors)")
end
```

### `degree_vector`

Get degree (number of connections) for each bus.

```julia
degree_vector(sys::PowerSystem{K}) -> Vector{Int}
```

**Example:**
```julia
sys = case14()
degrees = degree_vector(sys)

# Find hub buses (high degree)
hubs = findall(d -> d >= 4, degrees)
println("Hub buses: $hubs")
```

### `n_connected_components`

Count number of connected components.

```julia
n_connected_components(sys::PowerSystem{K}) -> Int
```

### `is_connected`

Check if network is fully connected.

```julia
is_connected(sys::PowerSystem{K}) -> Bool
```

**Example:**
```julia
sys = case14()
println("Connected: ", is_connected(sys))

# Disable a critical branch
sys.branches[1].in_service = false
println("After outage: ", is_connected(sys))
```

---

## Radial Network Analysis

### `is_radial`

Check if network has radial (tree) topology.

```julia
is_radial(sys::PowerSystem{K}) -> Bool
```

**Example:**
```julia
# Transmission networks are typically meshed
sys14 = case14()
println("IEEE 14-bus radial: ", is_radial(sys14))  # false

# Distribution networks are typically radial
sys33 = case_ieee33()
println("IEEE 33-bus radial: ", is_radial(sys33))  # true
```

### `leaf_buses`

Find leaf buses (degree = 1) in the network.

```julia
leaf_buses(sys::PowerSystem{K}) -> Vector{Int}
```

**Example:**
```julia
sys = case_ieee33()
leaves = leaf_buses(sys)
println("Leaf buses: $leaves")
```

---

## Topology Summary

### `topology_summary`

Generate comprehensive topology statistics.

```julia
topology_summary(sys::PowerSystem{K}) -> Dict{Symbol, Any}
```

**Returns dictionary with:**
- `:n_buses` — Number of buses
- `:n_branches` — Number of branches
- `:n_islands` — Number of connected components
- `:is_connected` — Whether fully connected
- `:is_radial` — Whether tree topology
- `:max_degree` — Maximum bus degree
- `:avg_degree` — Average bus degree
- `:leaf_buses` — List of leaf buses
- `:hub_buses` — Buses with degree ≥ 4

**Example:**
```julia
sys = case14()
summary = topology_summary(sys)

println("Topology Summary:")
println("  Buses: $(summary[:n_buses])")
println("  Branches: $(summary[:n_branches])")
println("  Islands: $(summary[:n_islands])")
println("  Radial: $(summary[:is_radial])")
println("  Max degree: $(summary[:max_degree])")
```

---

## Hybrid AC/DC Topology

### Converter Coupling Analysis

For hybrid systems, topology analysis considers AC-DC coupling through converters.

```julia
# Detect islands in hybrid system
hybrid = case_hybrid_5ac3dc()
islands = detect_islands(hybrid)

for island in islands
    println("Island $(island.index):")
    println("  AC buses: $(island.ac_buses)")
    println("  DC buses: $(island.dc_buses)")
end
```

### AC-DC Connectivity Graph

```julia
# Build combined adjacency including converter links
function hybrid_adjacency(hybrid::HybridPowerSystem)
    adj_ac = adjacency_list(hybrid.ac)
    adj_dc = adjacency_list(hybrid.dc)
    
    # Add converter links
    for conv in hybrid.vsc_converters
        # Converters create virtual edges between AC and DC buses
        push!(adj_ac[conv.bus_ac], -conv.bus_dc)  # Negative = DC bus
    end
    
    return adj_ac, adj_dc
end
```

---

## Use Cases

### N-1 Contingency Screening

```julia
function screen_n1_contingencies(sys::PowerSystem{AC})
    results = []
    
    for (i, branch) in enumerate(sys.branches)
        # Temporarily disable branch
        original_status = branch.in_service
        branch.in_service = false
        
        # Check connectivity
        n_islands = n_connected_components(sys)
        
        # Restore
        branch.in_service = original_status
        
        push!(results, (branch=i, islands=n_islands))
    end
    
    # Find critical branches
    critical = filter(r -> r.islands > 1, results)
    return critical
end
```

### Island-Aware Power Flow

```julia
function solve_islanded_power_flow(sys::PowerSystem{AC})
    islands = extract_islands(sys)
    results = []
    
    for (i, island_sys) in enumerate(islands)
        # Check if island is solvable
        island_info = detect_islands(island_sys)[1]
        
        if !island_info.has_reference
            println("Island $i has no reference bus - skipping")
            continue
        end
        
        # Solve each island independently
        result = solve_power_flow(island_sys)
        push!(results, result)
    end
    
    return results
end
```

### Topology Validation

```julia
function validate_topology(sys::PowerSystem{AC})
    errors = String[]
    
    # Check connectivity
    if !is_connected(sys)
        push!(errors, "Network is disconnected")
    end
    
    # Check for isolated buses
    degrees = degree_vector(sys)
    isolated = findall(d -> d == 0, degrees)
    if !isempty(isolated)
        push!(errors, "Isolated buses: $isolated")
    end
    
    # Check for reference bus
    has_ref = any(b -> b.bus_type == REF_BUS && b.in_service, sys.buses)
    if !has_ref
        push!(errors, "No reference bus")
    end
    
    return isempty(errors), errors
end
```

---

## Performance Notes

1. **Algorithm Complexity**: Island detection uses DFS with O(V + E) complexity
2. **Sparse Representation**: Adjacency lists are memory-efficient for sparse networks
3. **Incremental Updates**: For dynamic studies, consider caching adjacency structures
4. **Large Networks**: For networks > 10,000 buses, use parallel island detection
