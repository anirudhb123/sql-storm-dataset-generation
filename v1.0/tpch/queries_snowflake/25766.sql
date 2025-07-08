
WITH RankedSuppliers AS (
    SELECT 
        s.s_name, 
        r.r_name AS region_name, 
        SUM(ps.ps_supplycost) AS total_supply_cost, 
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_name, r.r_name
),
TopSuppliers AS (
    SELECT 
        region_name, 
        s_name, 
        total_supply_cost 
    FROM 
        RankedSuppliers 
    WHERE 
        rank <= 3
)
SELECT 
    region_name, 
    LISTAGG(s_name, ', ') AS top_suppliers, 
    SUM(total_supply_cost) AS total_cost
FROM 
    TopSuppliers
GROUP BY 
    region_name
ORDER BY 
    total_cost DESC;
