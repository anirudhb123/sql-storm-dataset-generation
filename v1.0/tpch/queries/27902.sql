SELECT 
    p.p_name,
    s.s_name,
    customers.customer_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
CROSS JOIN 
    (SELECT COUNT(DISTINCT c.c_custkey) AS customer_count 
     FROM customer c 
     WHERE c.c_acctbal > 1000) AS customers
WHERE 
    r.r_name LIKE '%North%'
GROUP BY 
    p.p_name, s.s_name, customers.customer_count
ORDER BY 
    total_quantity DESC, avg_price DESC;
