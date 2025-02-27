SELECT 
    p.p_mfgr,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    MAX(p.p_retailprice) AS max_price,
    AVG(p.p_retailprice) AS avg_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), ', ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_name LIKE '%widget%'
    AND s.s_acctbal > 1000
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_mfgr
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    avg_price DESC;