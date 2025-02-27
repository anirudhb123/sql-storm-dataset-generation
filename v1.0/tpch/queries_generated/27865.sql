SELECT 
    CONCAT('Part Name: ', SUBSTRING(p_name, 1, 30), '... | Manufacturer: ', p_mfgr, ' | Price: $', FORMAT(p_retailprice, 2), ' | Comments: ', p_comment) AS part_details,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE WHEN AVG(l_extendedprice) OVER (PARTITION BY l_partkey) > 100 THEN 1 ELSE 0 END) AS high_revenue_flag,
    CONCAT('Region: ', r_name, ' | Nation: ', n_name) AS location_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey LIMIT 1)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p_comment LIKE '%special%'
GROUP BY 
    p.p_partkey, p.p_name, p.mfgr, p.p_retailprice, p.p_comment, r.r_name, n.n_name
ORDER BY 
    supplier_count DESC, p.p_retailprice DESC
LIMIT 50;
