SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(LENGTH(p.p_comment)) AS avg_part_comment_length,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT n.n_name ORDER BY n.n_name SEPARATOR ', '), ',', 5) AS region_names,
    CONCAT('Total revenue from ', p.p_name, ' is ', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS revenue_statement
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
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    c.c_acctbal > 1000 
    AND p.p_retailprice > 50 
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    c.c_name, s.s_name, p.p_name
HAVING 
    total_orders > 10
ORDER BY 
    total_revenue DESC
LIMIT 100;
