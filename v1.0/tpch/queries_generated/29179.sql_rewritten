SELECT 
    p.p_name, 
    s.s_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    STRING_AGG(DISTINCT CONCAT(l.l_shipmode, ' (', l.l_returnflag, ')'), '; ') AS shipping_methods
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    s.s_acctbal > 5000 
    AND p.p_retailprice BETWEEN 10.00 AND 100.00 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name 
ORDER BY 
    revenue DESC, total_orders DESC
LIMIT 10;