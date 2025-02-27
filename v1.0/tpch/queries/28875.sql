SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUBSTRING(p.p_comment, 1, 10) AS truncated_comment,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CONCAT('Total Price: ', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS CHAR)) AS total_price_discounted
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 10
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_comment
ORDER BY 
    total_quantity DESC, avg_extended_price DESC
LIMIT 50;