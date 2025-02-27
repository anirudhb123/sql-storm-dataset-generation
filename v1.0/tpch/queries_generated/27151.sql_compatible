
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', region.r_name, ')'), ', ') AS supplying_nations
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region ON n.n_regionkey = region.r_regionkey 
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY 
    total_revenue DESC;
