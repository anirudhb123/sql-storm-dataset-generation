SELECT 
    p.p_name, 
    SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey 
JOIN 
    customer c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey) 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
GROUP BY 
    p.p_name, p.p_comment 
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5 
ORDER BY 
    returned_quantity DESC, short_comment;
