SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    CONCAT(c.c_address, ', ', n.n_name) AS customer_location,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT p.p_comment ORDER BY p.p_partkey DESC SEPARATOR '; '), '; ', 3) AS recent_comments
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    p.p_name LIKE '%widget%'
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey
ORDER BY 
    total_revenue DESC
LIMIT 50;
