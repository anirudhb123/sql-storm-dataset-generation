SELECT 
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS avg_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers_list,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customers_list,
    r.r_name AS region_name
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_brand, p.p_type, r.r_name
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;