SELECT 
    p.p_name, 
    s.s_name, 
    SUBSTRING(s.s_address, 1, 20) AS short_address, 
    c.c_name, 
    CONCAT('Total Price: $', ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS total_price,
    STRING_AGG( DISTINCT CONCAT(l.l_shipdate, ' - ', l.l_comment), '; ') AS shipping_details
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
GROUP BY 
    p.p_name, s.s_name, short_address, c.c_name 
ORDER BY 
    total_price DESC 
LIMIT 10;
