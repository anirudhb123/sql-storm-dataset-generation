
SELECT 
    CONCAT('Supplier: ', s.s_name, ' - Nation: ', n.n_name) AS supplier_nation_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END) AS avg_returned_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS unique_parts_supplied
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_comment LIKE '%reliable%' 
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    s.s_name, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
