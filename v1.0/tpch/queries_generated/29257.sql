WITH RankedSuppliers AS (
    SELECT 
        s.s_supkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS nation_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighVolumeSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_parts,
        rs.total_avail_qty,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.nation_rank <= 5
)
SELECT 
    region_name,
    nation_name,
    COUNT(supplier_name) AS num_top_suppliers,
    AVG(total_supply_cost) AS avg_supply_cost,
    SUM(total_avail_qty) AS total_available_quantity
FROM 
    HighVolumeSuppliers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;
