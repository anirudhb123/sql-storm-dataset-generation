SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' supplies ', p.p_name) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT p.p_type, ', ') AS unique_part_types,
    MAX(l.l_shipdate) AS latest_shipdate
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_name LIKE 'A%' 
GROUP BY 
    s.s_name, n.n_name, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00 
ORDER BY 
    total_orders DESC, total_revenue DESC;