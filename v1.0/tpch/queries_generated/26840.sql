SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    MAX(p.p_retailprice) AS max_price,
    MIN(p.p_retailprice) AS min_price,
    CONCAT('Total Quantity: ', SUM(l.l_quantity)) AS quantity_summary,
    AVG(l.l_extendedprice) AS avg_price,
    LEFT(p.p_comment, 20) AS short_comment,
    r.r_name AS region_name
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
WHERE 
    p.p_name LIKE '%widget%' 
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.s_suppkey) > 1
ORDER BY 
    total_quantity DESC, p.p_name;
