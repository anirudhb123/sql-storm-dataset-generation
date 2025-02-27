SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    r.r_name AS region_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%North%'
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_quantity DESC;