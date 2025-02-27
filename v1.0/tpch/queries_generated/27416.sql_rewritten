SELECT 
    CONCAT('Supplier: ', s_name, ' (', s_phone, ')') AS supplier_info,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    MAX(l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT p_name, ', ') AS supplied_parts
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > 10000
    AND l_shipdate >= DATE '1997-01-01'
GROUP BY 
    s.s_suppkey, s.s_name, s.s_phone
HAVING 
    COUNT(DISTINCT o_orderkey) > 5
ORDER BY 
    total_revenue DESC, last_ship_date DESC;