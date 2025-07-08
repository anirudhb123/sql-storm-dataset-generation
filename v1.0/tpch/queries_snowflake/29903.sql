
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(ps.ps_partkey) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        rs.s_name AS supplier_name, 
        rs.part_count, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 3
)
SELECT 
    ts.region_name, 
    ts.nation_name, 
    LISTAGG(ts.supplier_name, ', ') AS top_suppliers,
    SUM(ts.total_supply_cost) AS total_cost,
    COUNT(*) AS supplier_count
FROM 
    TopSuppliers ts
GROUP BY 
    ts.region_name, ts.nation_name
ORDER BY 
    total_cost DESC;
