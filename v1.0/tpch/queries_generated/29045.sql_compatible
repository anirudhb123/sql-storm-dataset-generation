
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(o.o_totalprice) AS max_order_price,
    MIN(o.o_orderdate) AS first_order_date,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier ', s.s_name, ' supplies ', COUNT(DISTINCT p.p_partkey), ' parts.') AS supplier_summary
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    s.s_name, p.p_name, SUBSTRING(p.p_comment, 1, 10)
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, avg_price ASC;
