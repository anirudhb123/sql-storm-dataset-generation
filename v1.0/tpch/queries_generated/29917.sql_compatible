
SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part Name: ', p.p_name, ' | Order Total: ', SUM(l.l_extendedprice * (1 - l.l_discount))) AS order_details,
    s.s_suppkey,
    p.p_partkey,
    s.s_nationkey,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_discount) AS avg_discount,
    MIN(l.l_extendedprice) AS min_price,
    MAX(l.l_extendedprice) AS max_price,
    STRING_AGG(DISTINCT CONCAT('Status: ', o.o_orderstatus), '; ') AS order_statuses,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    s.s_suppkey, p.p_partkey, s.s_name, p.p_name, s.s_nationkey
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    order_count DESC, avg_discount ASC;
