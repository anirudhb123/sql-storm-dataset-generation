
SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    COUNT(DISTINCT CASE 
        WHEN LENGTH(p.p_comment) > 0 THEN p.p_partkey 
        END) AS non_empty_comments
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
    r.r_name LIKE 'Asia%'
GROUP BY 
    p.p_name, p.p_mfgr, p.p_type
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_retail_price DESC
LIMIT 10;
