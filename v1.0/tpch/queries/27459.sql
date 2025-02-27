
SELECT 
    CONCAT(c.c_name, ' (', SUBSTRING(s.s_name, 1, 10), ')') AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_list
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    c.c_acctbal > 1000.00 
    AND o.o_orderstatus = 'O'
    AND p.p_size BETWEEN 10 AND 20
GROUP BY 
    c.c_custkey, s.s_suppkey, c.c_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 50
ORDER BY 
    total_revenue DESC;
