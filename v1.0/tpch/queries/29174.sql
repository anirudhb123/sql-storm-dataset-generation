SELECT 
    c.c_name AS customer_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_extendedprice) AS avg_line_item_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1998-01-01'
    AND l.l_returnflag = 'N'
GROUP BY 
    c.c_name, r.r_name
ORDER BY 
    total_revenue DESC, total_orders ASC;