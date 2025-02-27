SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    n.n_name AS nation_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(CONCAT('Order:', o.o_orderkey, ' Status:', o.o_orderstatus), '; ') AS order_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10 AND 
    o.o_orderdate >= DATE '1997-01-01' AND 
    o.o_orderdate < DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_quantity DESC, avg_price ASC;