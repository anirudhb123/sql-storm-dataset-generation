SELECT 
    CONCAT('Supplier: ', s.s_name, ' (', s.s_suppkey, ') - Address: ', s.s_address, ' | Nation: ', n.n_name) AS supplier_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    STRING_AGG(DISTINCT CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned' 
        ELSE 'Not Returned' 
    END, ', ') AS return_status,
    r.r_name AS region_name
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
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    s.s_suppkey, s.s_name, s.s_address, n.n_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;