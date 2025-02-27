SELECT 
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS average_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_comment END, '; ') AS return_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE ' rubber%'
    AND n.n_name IN (SELECT DISTINCT n_name FROM nation WHERE n_regionkey = 1)
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_quantity DESC, average_price ASC;