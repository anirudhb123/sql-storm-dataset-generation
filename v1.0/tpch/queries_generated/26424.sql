SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUBSTRING_INDEX(p.p_comment, ' ', 3) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice >= 100.00 
    AND o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, r.r_name
HAVING 
    total_revenue > 100000
ORDER BY 
    total_revenue DESC;
