SELECT 
    p.p_name, 
    LENGTH(p.p_comment) AS comment_length, 
    SUBSTRING_INDEX(r.r_name, ' ', 1) AS region_first_word, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    CONCAT(LEFT(c.c_name, 10), '...') AS customer_name_excerpt,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned_value
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    customer c ON l.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey LIMIT 1)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100.00 
    AND r.r_name LIKE '%North%'
GROUP BY 
    p.p_name, r.r_name, c.c_name
ORDER BY 
    total_returned_value DESC, comment_length ASC
LIMIT 10;
