WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        rs.s_name,
        rs.total_cost
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.s_nationkey)
    WHERE 
        rs.rank <= 5
)
SELECT 
    r.r_name AS region,
    STRING_AGG(s.s_name, ', ') AS top_suppliers,
    SUM(s.total_cost) AS total_supply_cost
FROM 
    TopSuppliers s
JOIN 
    region r ON r.r_name = s.r_name
GROUP BY 
    r.r_name
ORDER BY 
    total_supply_cost DESC;
