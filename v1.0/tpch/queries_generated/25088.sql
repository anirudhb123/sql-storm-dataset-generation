SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    MAX(l.l_extendedprice) AS max_extended_price,
    MIN(l.l_discount) AS min_discount,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT CONCAT(s.s_name), ', ' ORDER BY s.s_name SEPARATOR ', '), ', ', 5) AS top_suppliers,
    CONCAT('Parts in Category: ', p.p_container, ' | Region: ', r.r_name) AS part_region_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    r.r_name LIKE 'Amer%'
GROUP BY 
    p.p_partkey
HAVING 
    total_returned > 10
ORDER BY 
    supplier_count DESC, max_extended_price DESC;
