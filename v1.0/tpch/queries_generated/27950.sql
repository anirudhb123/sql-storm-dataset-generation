WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
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
        s.s_name AS supplier_name,
        ts.total_supply_cost
    FROM 
        RankedSuppliers ts
    JOIN 
        nation n ON ts.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ts.rn <= 3
)
SELECT 
    region_name,
    nation_name,
    STRING_AGG(supplier_name, ', ') AS top_suppliers,
    SUM(total_supply_cost) AS total_cost
FROM 
    TopSuppliers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, total_cost DESC;
