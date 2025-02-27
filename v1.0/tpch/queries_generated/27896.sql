SELECT 
    CONCAT(s.s_name, ' (', s.s_nationkey, ')') AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING_INDEX(p.p_name, ' ', 1) AS primary_keyword,
    RANK() OVER (PARTITION BY SUBSTRING_INDEX(p.p_name, ' ', 1) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
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
WHERE 
    s.s_comment NOT LIKE '%discount%'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    supplier_info, primary_keyword
HAVING 
    total_orders > 10
ORDER BY 
    total_revenue DESC, revenue_rank ASC;
