SELECT 
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Location: ', s.s_address) AS supplier_info,
    SUM(l.l_quantity) AS total_quantity,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 5 THEN 'High Volume' 
        ELSE 'Low Volume' 
    END AS order_volume_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
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
    p.p_size > 10 AND 
    s.s_acctbal > 5000.00 AND 
    o.o_orderdate >= DATE '1995-01-01'
GROUP BY 
    p.p_name, s.s_name, s.s_address 
ORDER BY 
    total_quantity DESC;