SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) AS total_fully_filled,
    AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS avg_price_after_discount,
    string_agg(DISTINCT r.r_name, ', ') AS regions_supplied
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
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
WHERE 
    p.p_name LIKE '%rubber%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_partkey, p.p_name, s.s_name 
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 
ORDER BY 
    total_fully_filled DESC;