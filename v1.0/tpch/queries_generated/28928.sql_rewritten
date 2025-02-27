SELECT 
    p.p_name AS part_name,
    p.p_mfgr AS manufacturer,
    p.p_brand AS brand,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_sales,
    AVG(l.l_quantity) AS average_quantity,
    STRING_AGG(DISTINCT p.p_comment, ', ') AS all_comments
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
    p.p_size BETWEEN 10 AND 50
    AND l.l_shipdate >= DATE '1997-01-01'
    AND n.n_name LIKE 'A%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, r.r_name, n.n_name, s.s_name
ORDER BY 
    total_sales DESC, average_quantity DESC
LIMIT 100;