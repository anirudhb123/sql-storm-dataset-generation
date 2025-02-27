
SELECT 
    p.p_name, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_extendedprice) AS max_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS supplier_details
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_name LIKE '%Steel%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) > 0
ORDER BY 
    total_orders DESC
LIMIT 10;
