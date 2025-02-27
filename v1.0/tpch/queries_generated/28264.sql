SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    MAX(l.l_extendedprice) AS max_price,
    MIN(l.l_discount) AS min_discount,
    SUBSTR(LOWER(p.p_comment), 1, 20) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100.00 
    AND n.n_name LIKE 'A%'
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > 500
ORDER BY 
    supplier_count DESC, 
    total_quantity DESC;
