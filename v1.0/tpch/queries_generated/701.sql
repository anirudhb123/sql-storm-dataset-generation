WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    rs.s_name AS supplier_name,
    rs.total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_price_per_order
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey
    )
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    r.r_name IS NOT NULL 
GROUP BY 
    r.r_name, n.n_name, rs.s_name, rs.total_supply_cost
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0 AND 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    region_name ASC, total_supply_cost DESC;
