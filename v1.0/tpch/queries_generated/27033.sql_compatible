
SELECT 
    CONCAT(c.c_name, ' from ', s.s_name) AS supplier_customer, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(p.p_name, ', ') AS products_sold
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    c.c_acctbal > 10000 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    c.c_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY 
    total_revenue DESC;
