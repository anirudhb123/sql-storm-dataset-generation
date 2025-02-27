SELECT 
    c.c_name AS customer_name,
    CONCAT(s.s_name, ' (', CAST(s.s_acctbal AS varchar), '): ', 
           s.s_address, ', ', n.n_name) AS supplier_info,
    p.p_name AS part_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_brand LIKE 'Brand#%'
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    c.c_name, s.s_name, s.s_acctbal, s.s_address, n.n_name, p.p_name, p.p_comment
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC,
    customer_name ASC;
