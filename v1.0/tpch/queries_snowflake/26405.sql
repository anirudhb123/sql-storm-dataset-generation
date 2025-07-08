
WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_name,
        r.r_name AS region_name,
        rs.total_supply_value
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
    LISTAGG(ts.s_name, ', ') AS top_suppliers,
    SUM(ts.total_supply_value) AS total_value
FROM 
    TopSuppliers ts
GROUP BY 
    ts.region_name
ORDER BY 
    total_value DESC;
