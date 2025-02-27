SELECT 
    p.p_brand,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    CONCAT('Region: ', r.r_name, ' (', COUNT(DISTINCT n.n_nationkey), ' Nations)') AS region_info
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
WHERE 
    p.p_retailprice > 50.00
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_brand, r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    total_avail_qty DESC, avg_retail_price ASC;
