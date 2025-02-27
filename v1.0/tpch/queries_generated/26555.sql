SELECT 
    p.p_partkey,
    TRIM(p.p_name) AS part_name,
    CASE WHEN LENGTH(p.p_comment) > 20 THEN SUBSTRING(p.p_comment FROM 1 FOR 20) || '...' ELSE p.p_comment END AS short_comment,
    (SELECT COUNT(DISTINCT ps.s_suppkey) 
     FROM partsupp ps 
     WHERE ps.ps_partkey = p.p_partkey) AS supplier_count,
    (SELECT AVG(l.l_discount) 
     FROM lineitem l 
     WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R') AS avg_discount_returned
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
WHERE 
    c.c_mktsegment = 'BUILDING'
    AND p.p_size BETWEEN 1 AND 10
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    supplier_count DESC, 
    avg_discount_returned ASC
LIMIT 50;
