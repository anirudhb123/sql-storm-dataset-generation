SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUBSTRING(s.s_comment, 1, 50) AS supplier_comment_snippet, 
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     WHERE c.c_nationkey = s.s_nationkey) AS customer_count, 
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_order_value, 
    STRING_AGG(DISTINCT CAST(n.n_name AS VARCHAR), ', ') AS nation_names
FROM 
    supplier s 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    s.s_name, p.p_name 
HAVING 
    AVG(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    customer_count DESC, avg_order_value DESC;
