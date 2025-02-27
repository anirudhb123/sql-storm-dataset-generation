SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name,
    o.o_orderkey, 
    o.o_orderdate, 
    COUNT(l.l_partkey) AS lineitem_count,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_tax) AS highest_tax,
    STRING_AGG(DISTINCT CONCAT(p.p_comment, ' - ', s.s_comment), '; ') AS combined_comments
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
WHERE 
    p.p_retailprice > 50.00 
    AND o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate
HAVING 
    COUNT(l.l_partkey) > 5
ORDER BY 
    total_extended_price DESC
LIMIT 100;