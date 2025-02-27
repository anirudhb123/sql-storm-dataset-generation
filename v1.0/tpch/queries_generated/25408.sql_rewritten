SELECT 
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(o.o_totalprice) AS max_order_value,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_comment LIKE '%fragile%'
GROUP BY 
    supplier_info, part_name
ORDER BY 
    total_revenue DESC
LIMIT 10;