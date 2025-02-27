SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN l.l_extendedprice END) AS total_open_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice END) AS total_returns,
    AVG(l.l_discount) AS average_discount,
    SUBSTRING(s.s_comment, 1, 20) AS short_supplier_comment,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation
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
    LENGTH(s.s_comment) > 0 AND
    p.p_retailprice BETWEEN 100.00 AND 500.00
GROUP BY 
    s.s_name, p.p_name, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_open_orders DESC, average_discount ASC;
