SELECT 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
        WHEN o.o_orderstatus = 'O' THEN DATEDIFF(l.l_shipdate, o.o_orderdate) 
        ELSE NULL 
    END) AS avg_shipping_time,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_container, ')'), ', ') AS products,
    MAX(p.p_retailprice) AS highest_price
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'N%'
GROUP BY 
    r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
