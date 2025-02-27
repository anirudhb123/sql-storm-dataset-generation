SELECT 
    CONCAT('Part Name: ', p_name, ', Manufacturer: ', p_mfgr, 
           ', Retail Price: $', FORMAT(p_retailprice, 2), 
           ', Comment: ', CASE 
                           WHEN LENGTH(p_comment) > 10 THEN SUBSTRING(p_comment, 1, 10) || '...' 
                           ELSE p_comment 
                         END) AS formatted_part_info,
    r_name AS region_name,
    n_name AS nation_name,
    s_name AS supplier_name,
    COUNT(DISTINCT c_custkey) AS unique_customers
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
    p_size BETWEEN 10 AND 20 
    AND r_name LIKE '%Asia%'
GROUP BY 
    p.p_partkey, r.r_regionkey, n.n_nationkey, s.s_suppkey
ORDER BY 
    unique_customers DESC, p_name;
