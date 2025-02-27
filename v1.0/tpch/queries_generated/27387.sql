SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' (', r.r_name, ')') AS supplier_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_quantity) AS avg_quantity,
    MIN(DATE_FORMAT(o.o_orderdate, '%Y-%m-%d')) AS first_order_date,
    MAX(DATE_FORMAT(o.o_orderdate, '%Y-%m-%d')) AS last_order_date
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
    r.r_name LIKE 'Asia%' AND 
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    supplier_info
HAVING 
    total_revenue > 100000
ORDER BY 
    total_revenue DESC;
