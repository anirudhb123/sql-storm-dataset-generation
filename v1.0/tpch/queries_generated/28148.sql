SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 50)
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    avg_retail_price DESC, supplier_count DESC;
