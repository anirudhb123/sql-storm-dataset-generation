SELECT 
    ps.ps_partkey,
    p.p_name,
    s.s_name,
    c.c_name,
    CONCAT(c.c_address, ', ', s.s_address) AS full_address,
    SUBSTRING(p.p_comment, 0, 21) AS shortened_comment,
    DATE_FORMAT(o.o_orderdate, '%Y-%m-%d') AS order_date,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(ls.l_discount) AS average_discount,
    MAX(ps.ps_supplycost) AS maximum_supply_cost
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    lineitem ls ON ls.l_orderkey = o.o_orderkey
WHERE 
    p.p_brand LIKE '%Brand%'
    AND s.s_comment NOT LIKE '%fragile%'
    AND o.o_orderstatus = 'O'
GROUP BY 
    ps.ps_partkey, p.p_name, s.s_name, c.c_name, c.c_address, s.s_address, o.o_orderdate
ORDER BY 
    total_quantity DESC
LIMIT 100;
