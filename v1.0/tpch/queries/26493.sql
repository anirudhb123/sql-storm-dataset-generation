SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(p.p_retailprice) AS average_price,
    SUM(l.l_quantity) AS total_quantity,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
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
    p.p_type LIKE '%BRASS%'
    AND o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    average_price DESC;