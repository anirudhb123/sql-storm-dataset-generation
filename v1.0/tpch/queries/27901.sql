SELECT 
    p.p_brand,
    COUNT(DISTINCT s.s_name) AS supplier_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), ', ') AS supplier_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    p.p_type LIKE '%metal%' 
    AND s.s_acctbal > 10000
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_brand
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    avg_price DESC;