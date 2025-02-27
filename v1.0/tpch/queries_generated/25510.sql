SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_discount) AS max_discount,
    LOWER(SUBSTRING_INDEX(p.p_name, ' ', 1)) AS first_word,
    CONCAT(UPPER(SUBSTRING(s.s_name, 1, 1)), LOWER(SUBSTRING(s.s_name, 2))) AS formatted_supplier_name
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
    l.l_shipdate BETWEEN '2023-01-01' AND CURRENT_DATE
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    total_orders > 5
ORDER BY 
    total_quantity DESC, avg_price ASC
LIMIT 10;
