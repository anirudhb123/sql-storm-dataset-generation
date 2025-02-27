SELECT 
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info,
    SUBSTRING_INDEX(p.p_name, ' ', 1) AS part_name,
    COUNT(l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    supplier_info, part_name
HAVING 
    COUNT(l.l_orderkey) > 5 AND total_revenue > 1000
ORDER BY 
    revenue_rank, total_revenue DESC;
