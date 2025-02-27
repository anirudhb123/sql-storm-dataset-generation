SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS avg_order_total,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    STRING_AGG(DISTINCT p.p_name, ', ') AS unique_part_names
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    n.n_name LIKE 'A%' AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    avg_order_total DESC;