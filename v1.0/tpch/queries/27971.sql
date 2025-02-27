SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ' in ', r.r_name) AS supplier_customer_details, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_container, ')'), ', ') AS products_supplied
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_retailprice > 50.00
GROUP BY 
    c.c_name, s.s_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;