SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT CONCAT(s.s_address, ' (', s.s_phone, ')'), '; ') AS supplier_details
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
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
    AND s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
ORDER BY 
    total_quantity DESC, part_name ASC;