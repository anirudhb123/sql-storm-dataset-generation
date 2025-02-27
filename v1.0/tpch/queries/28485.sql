
SELECT 
    CONCAT(s.s_name, ' from ', CONCAT(c.c_name, ' in ', r.r_name)) AS supplier_info,
    SUBSTRING(p.p_name, 1, 10) AS part_excerpt,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(l.l_shipmode, ', ') AS unique_shipping_modes
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice BETWEEN 100.00 AND 500.00
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderstatus = 'O'
GROUP BY 
    s.s_name, c.c_name, r.r_name, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC;
