SELECT 
    CONCAT(c.c_name, ' from ', r.r_name) AS supplier_region,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
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
    o.o_orderstatus = 'O' 
    AND l.l_shipdate >= DATE '1997-01-01' 
    AND l.l_shipdate < DATE '1998-01-01'
GROUP BY 
    supplier_region
ORDER BY 
    total_revenue DESC
LIMIT 10;