WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
)

SELECT 
    r.r_name AS region,
    COUNT(DISTINCT rs.s_suppkey) AS num_suppliers,
    SUM(rs.total_supply_cost) AS total_cost
FROM 
    RankedSuppliers rs
JOIN 
    region r ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        WHERE n.n_name = rs.supplier_nation 
        LIMIT 1
    )
WHERE 
    rs.rank <= 5
GROUP BY 
    r.r_name
ORDER BY 
    total_cost DESC;
