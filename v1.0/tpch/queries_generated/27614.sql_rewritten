SELECT 
    p.p_partkey,
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_info,
    STRING_AGG(DISTINCT CONCAT('Customer: ', c.c_name, ' (', c.c_nationkey, ')'), '; ') AS customer_details,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;