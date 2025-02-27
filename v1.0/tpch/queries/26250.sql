SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 50.00 
    AND l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;