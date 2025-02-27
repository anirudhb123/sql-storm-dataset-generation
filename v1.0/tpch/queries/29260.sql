SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(l.l_discount) AS average_discount
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE 'N%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr
ORDER BY 
    total_order_value DESC
LIMIT 20;
