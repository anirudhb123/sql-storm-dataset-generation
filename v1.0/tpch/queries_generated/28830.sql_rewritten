SELECT 
    p.p_name, 
    CONCAT(s.s_name, ' ', s.s_address, ', ', r.r_name) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS ship_modes
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
WHERE 
    p.p_brand LIKE 'Brand%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, supplier_info
ORDER BY 
    order_count DESC, avg_order_value DESC, p.p_name;