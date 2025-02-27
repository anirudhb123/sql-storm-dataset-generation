SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    MAX(CASE WHEN l.l_returnflag = 'Y' THEN l.l_extendedprice ELSE 0 END) AS max_returned_price,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS unique_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_size > 10 AND
    l.l_shipdate >= '2023-01-01' AND
    l.l_shipdate < '2024-01-01'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_quantity DESC, part_name ASC;
