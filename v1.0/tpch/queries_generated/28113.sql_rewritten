SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name, 
    s.s_name AS supplier_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_container, ')'), ', ') AS part_names,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
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
WHERE 
    r.r_name LIKE '%West%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;