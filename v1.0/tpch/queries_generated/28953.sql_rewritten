SELECT 
    s.s_name AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' ', c.c_address), '; ') AS customer_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_brand LIKE 'Brand#%'
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderstatus = 'O'
GROUP BY 
    s.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10;