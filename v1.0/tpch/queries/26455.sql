SELECT 
    p.p_name AS product_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_quantity) AS avg_quantity,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS product_comments
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC;