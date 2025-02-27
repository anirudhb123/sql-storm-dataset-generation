SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    AVG(p.p_retailprice) AS avg_retail_price,
    MAX(p.p_size) AS max_part_size,
    MIN(p.p_size) AS min_part_size
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 50.00 AND
    s.s_acctbal > 0
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    supplier_count DESC, avg_retail_price DESC
LIMIT 10;
