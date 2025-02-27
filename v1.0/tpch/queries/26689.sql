SELECT 
    p.p_name, 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info, 
    COUNT(*) AS order_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS aggregated_comments
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
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND s.s_acctbal > 500
    AND l.l_discount < 0.1
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_quantity DESC
LIMIT 100;