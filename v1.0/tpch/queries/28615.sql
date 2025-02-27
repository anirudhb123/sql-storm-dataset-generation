SELECT 
    CONCAT(s.s_name, ' from ', r.r_name) AS supplier_region,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS average_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(o.o_orderdate) AS last_order_date
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'Europ%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    supplier_region
ORDER BY 
    total_revenue DESC
LIMIT 10;