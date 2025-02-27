
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    CONCAT(s.s_address, ', ', n.n_name) AS supplier_location, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
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
    p.p_size > 10
    AND s.s_acctbal > 5000.00
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_quantity DESC, avg_price ASC;
