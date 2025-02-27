SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    COUNT(l.l_orderkey) AS line_item_count,
    SUM(l.l_extendedprice) AS total_extended_price,
    SUM(l.l_discount) AS total_discount,
    SUM(l.l_tax) AS total_tax,
    GROUP_CONCAT(DISTINCT CONCAT(ps.ps_comment, ' (Cost: ', ps.ps_supplycost, ')') ORDER BY ps_supplycost DESC SEPARATOR '; ') AS supplier_comments
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
    p.p_comment LIKE '%fragile%'
    AND s.s_comment NOT LIKE '%not available%'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey, o.o_orderkey
HAVING 
    total_extended_price > 1000
ORDER BY 
    total_extended_price DESC;
