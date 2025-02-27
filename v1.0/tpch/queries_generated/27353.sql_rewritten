SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS average_quantity,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', r.r_name, ')'), ', ') AS nation_region_info
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_comment LIKE '%eco%'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, supplier_name ASC;