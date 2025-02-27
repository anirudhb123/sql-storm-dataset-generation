SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_name) AS supplier_count,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS total_revenue,
    MAX(o.o_totalprice) AS max_order_value,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS suppliers_list
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%green%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;