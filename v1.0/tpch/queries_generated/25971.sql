SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    GROUP_CONCAT(DISTINCT CONCAT('Order ID: ', o.o_orderkey, ' (', o.o_orderdate, ')') ORDER BY o.o_orderdate ASC SEPARATOR '; ') AS order_details
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    c.c_mktsegment = 'BUILDING' 
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
