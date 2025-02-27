
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name, ', Part Name: ', p.p_name) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS avg_return_qty,
    MAX(p.p_retailprice) AS max_part_price,
    MIN(p.p_retailprice) AS min_part_price,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS unique_comments
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    s.s_name, n.n_name, p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;
