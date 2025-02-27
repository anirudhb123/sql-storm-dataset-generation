SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    orders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    p.p_name
ORDER BY 
    total_price DESC
LIMIT 10;
