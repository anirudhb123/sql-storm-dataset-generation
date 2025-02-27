SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
    CONCAT('Order placed by ', c.c_name, ' for part ', p.p_name, ' from supplier ', s.s_name, ' at a price of ', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2), ' USD.') AS order_description
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    o.o_orderstatus = 'F'
    AND c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    total_price > 1000
ORDER BY 
    total_price DESC
LIMIT 10;
