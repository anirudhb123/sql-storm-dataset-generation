WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_supply_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        ss.total_supply_cost,
        ss.part_supply_count,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
),
RegionSummary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    ts.s_name,
    ts.total_supply_cost,
    ts.part_supply_count,
    rs.r_name,
    rs.nation_count,
    rs.supplier_count
FROM 
    TopSuppliers ts
JOIN 
    nation n ON n.n_nationkey = (
        SELECT s_nationkey FROM supplier WHERE s_name = ts.s_name LIMIT 1
    )
JOIN 
    region rs ON n.n_regionkey = rs.r_regionkey
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.rank;
