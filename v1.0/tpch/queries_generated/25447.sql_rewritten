SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    r.r_name AS region_name,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_quantity 
        ELSE 0 
    END) AS total_returned_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
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
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND p.p_size > 20
GROUP BY 
    s.s_name, r.r_name
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;