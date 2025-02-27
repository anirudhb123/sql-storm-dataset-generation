
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    MAX(p.p_retailprice) AS max_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Total $$ ', ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS total_sales
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 10 AND 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
