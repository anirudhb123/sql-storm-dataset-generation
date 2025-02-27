SELECT 
    SUBSTRING(p_name, 1, 10) AS truncated_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_tax ELSE NULL END) AS max_return_tax,
    MIN(CASE WHEN l.l_linestatus = 'O' THEN l.l_discount ELSE NULL END) AS min_open_discount,
    CONCAT(n.n_name, ' - ', r.r_name) AS region_nation,
    REPLACE(SUBSTRING(p_comment, 1, 20), ' ', '_') AS modified_comment
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p_brand LIKE 'Brand%' 
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    truncated_name, region_nation
ORDER BY 
    supplier_count DESC, total_quantity DESC
LIMIT 100;
