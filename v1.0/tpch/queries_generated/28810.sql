SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS shipping_modes,
    MIN(o.o_orderdate) AS first_order_date,
    MAX(o.o_orderdate) AS last_order_date,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Demand'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND n.n_name IN ('USA', 'Canada')
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 10
ORDER BY 
    total_quantity DESC, part_name ASC
LIMIT 50;
