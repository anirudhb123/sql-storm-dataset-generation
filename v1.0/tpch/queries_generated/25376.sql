SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT CONCAT(c.c_name, '(', c.c_acctbal, ')'), '; ') AS customers
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    s.s_acctbal > 100.00
    AND l.l_discount BETWEEN 0.05 AND 0.20
    AND p.p_size IN (10, 20, 30)
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY 
    total_revenue DESC;
