SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(CASE WHEN l.l_discount > 0.05 THEN l.l_extendedprice ELSE NULL END) AS max_extended_price_with_discount,
    CONCAT('Total Customer Count in ', n.n_name, ': ', COUNT(DISTINCT c.c_custkey)) AS customer_summary,
    SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT p.p_name ORDER BY p.p_name SEPARATOR ', '), ', ', 5), ', ', -5) AS top_part_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
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
    r.r_name LIKE 'Asia%'
GROUP BY 
    n.n_name
HAVING 
    total_quantity > 100
ORDER BY 
    customer_count DESC;
