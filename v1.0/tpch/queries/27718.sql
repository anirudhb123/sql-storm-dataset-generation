SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS avg_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC
LIMIT 10;