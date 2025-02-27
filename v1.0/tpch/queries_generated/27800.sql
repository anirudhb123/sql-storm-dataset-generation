SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTR(s.s_comment, 1, 20) AS short_comment,
    LEFT(r.r_name, 5) AS short_region_name
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
    s.s_name LIKE 'Supplier%'
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    s.s_name, short_comment, short_region_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC, order_count ASC;
