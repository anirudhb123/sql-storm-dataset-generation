SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(p.p_retailprice) AS max_price,
    MIN(p.p_retailprice) AS min_price,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    STRING_AGG(n.n_name, ', ') AS nation_names
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_quantity DESC, p.p_name ASC
LIMIT 50;
