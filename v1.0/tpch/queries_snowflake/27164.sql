
WITH RankedSuppliers AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC, SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.supplier_name,
        r.r_name AS region_name,
        rs.part_count,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    ts.region_name,
    LISTAGG(ts.supplier_name, ', ') WITHIN GROUP (ORDER BY ts.supplier_name) AS top_suppliers,
    SUM(ts.part_count) AS total_parts_supplied,
    SUM(ts.total_supply_cost) AS total_cost
FROM 
    TopSuppliers ts
GROUP BY 
    ts.region_name
ORDER BY 
    total_cost DESC;
