SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING_INDEX(SUBSTRING_INDEX(s.s_name, ' ', 1), ' ', -1) AS supplier_first_name,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation
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
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND r.r_name IN ('ASIA', 'EUROPE')
GROUP BY 
    p.p_name, supplier_first_name, region_nation
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC, order_count DESC;
