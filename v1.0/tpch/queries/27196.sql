
SELECT 
    p.p_name, 
    CONCAT(s.s_name, ' (', s.s_address, ')') AS supplier_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names,
    LEFT(p.p_comment, 20) AS short_comment,
    r.r_name AS region_name
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
    r.r_name LIKE 'S%' AND 
    l.l_shipmode IN ('AIR', 'MAIL')
GROUP BY 
    p.p_name, s.s_name, s.s_address, r.r_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
