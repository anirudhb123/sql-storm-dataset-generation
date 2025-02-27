SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(p.p_retailprice) AS average_retail_price, 
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS market_segments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%Steel%' 
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5 
ORDER BY 
    total_quantity DESC;
