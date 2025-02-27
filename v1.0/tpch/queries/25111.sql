SELECT 
    p.p_name AS part_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT(s.s_name, ' in ', r.r_name) AS supplier_region,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    MAX(p.p_retailprice) AS max_price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 100.00 AND 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment, s.s_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;