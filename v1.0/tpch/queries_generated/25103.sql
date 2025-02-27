SELECT 
    CONCAT('Supplier: ', s_name, ' | Part: ', p_name, ' | Price: ', FORMAT(ps_supplycost, 2), 
           ' | Comment: ', ps_comment) AS supplier_part_info,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT r_name ORDER BY r_name SEPARATOR ', '), ', ', 5) AS top_regions,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    MAX(o_orderdate) AS last_order_date
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
    p.p_name LIKE '%widget%'
    AND o.o_orderstatus = 'F'
    AND l_shipdate >= '2023-01-01'
GROUP BY 
    s.s_suppkey, p.p_partkey
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
