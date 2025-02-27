SELECT 
    p.p_name AS part_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MAX(o.o_orderdate) AS last_order_date,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 10
GROUP BY 
    p.p_partkey, p.p_name, r.r_name, n.n_name, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_available_quantity DESC, avg_order_value ASC
LIMIT 100;
