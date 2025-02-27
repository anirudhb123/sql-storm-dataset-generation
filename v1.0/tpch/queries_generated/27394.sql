SELECT 
    CONCAT(s.s_name, ' (', s.s_suppkey, ')') AS supplier_info,
    p.p_name,
    SUBSTRING_INDEX(p.p_comment, ' ', 3) AS short_comment,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%USA%')
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    s.s_suppkey, p.p_partkey
HAVING 
    total_quantity > 100
ORDER BY 
    total_revenue DESC;
