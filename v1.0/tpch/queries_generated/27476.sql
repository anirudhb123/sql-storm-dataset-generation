SELECT
    p.p_name,
    s.s_name,
    n.n_name AS supplier_nation,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(l.l_discount) AS max_discount,
    MIN(CASE WHEN l.l_returnflag = 'R' THEN l.l_receiptdate END) AS first_return_date,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS comments_summary
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%widget%'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_revenue DESC,
    total_orders DESC
LIMIT 10;
