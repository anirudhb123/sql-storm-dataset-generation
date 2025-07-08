
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    c.c_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    LISTAGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_info,
    LISTAGG(DISTINCT CONCAT(c.c_name, ' (', c.c_address, ')'), '; ') WITHIN GROUP (ORDER BY c.c_name) AS customer_info
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
    p.p_name LIKE '%widget%' 
    AND o.o_orderstatus = 'O' 
    AND l.l_shipmode IN ('AIR', 'GROUND')
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name
ORDER BY 
    total_quantity DESC, avg_extended_price DESC
LIMIT 100;
