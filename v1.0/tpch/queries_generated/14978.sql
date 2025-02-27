SELECT 
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
