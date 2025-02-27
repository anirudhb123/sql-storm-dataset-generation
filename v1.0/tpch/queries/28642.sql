
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS max_returned_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    SUBSTRING(p.p_comment FROM 1 FOR 23) AS truncated_comment
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
WHERE 
    p.p_type LIKE '%BRASS%'
GROUP BY 
    s.s_name, p.p_name, ps.ps_availqty, p.p_retailprice, l.l_returnflag, n.n_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_orders DESC, supplier_name;
