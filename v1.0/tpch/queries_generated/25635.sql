SELECT 
    CONCAT('Supplier: ', s_name, ', Nation: ', n_name, ', Part Name: ', p_name) AS supplier_info,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    AVG(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE NULL END) AS avg_return_qty,
    MAX(p_retailprice) AS max_part_price,
    MIN(p_retailprice) AS min_part_price,
    GROUP_CONCAT(DISTINCT p_comment SEPARATOR '; ') AS unique_comments
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
    supplier_info
ORDER BY 
    revenue DESC
LIMIT 10;
