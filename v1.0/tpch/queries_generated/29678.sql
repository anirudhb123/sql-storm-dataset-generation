SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_open_orders,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', s.s_name, ')'), ', ') AS supplied_parts,
    MAX(p.p_retailprice) AS highest_price_part,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END) AS avg_returned_price
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    n.n_name LIKE 'A%' 
GROUP BY 
    n.n_name
ORDER BY 
    total_customers DESC, total_open_orders DESC;
