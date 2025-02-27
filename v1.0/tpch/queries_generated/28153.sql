SELECT 
    p.p_name AS part_name,
    CONCAT(s.s_name, ' (', s.s_address, ')') AS supplier_info,
    SUM(ps.ps_availqty) AS total_avail_qty,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_orderdate) AS last_order_date,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT c.c_name ORDER BY c.c_name ASC SEPARATOR ', '), ',', 5) AS top_customers,
    REGEXP_REPLACE(SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT r.r_name ORDER BY r.r_name ASC SEPARATOR ', '), ',', 3), '(.{10})', '\\1...') AS regions_involved
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
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
    p.p_size BETWEEN 10 AND 30 AND 
    LENGTH(p.p_comment) > 15 AND 
    o.o_orderstatus IN ('O', 'F') 
GROUP BY 
    p.p_partkey, s.s_suppkey
HAVING 
    total_avail_qty > 100
ORDER BY 
    total_orders DESC, last_order_date DESC
LIMIT 20;
