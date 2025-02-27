SELECT 
    CONCAT('Supplier: ', s.s_name, '; Nation: ', n.n_name, '; Region: ', r.r_name) AS supplier_info,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(o.o_totalprice) AS max_order_value
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
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
WHERE 
    r.r_name LIKE '%ASIA%'
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY 
    s.s_suppkey, s.s_name, n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_revenue DESC;