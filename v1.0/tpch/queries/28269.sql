SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    MAX(o.o_totalprice) AS max_order_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    short_name
HAVING 
    AVG(l.l_quantity) > 100
ORDER BY 
    supplier_count DESC, short_name ASC;
