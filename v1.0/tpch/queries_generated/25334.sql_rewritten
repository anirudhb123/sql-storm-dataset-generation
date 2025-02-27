SELECT 
    p.p_name AS part_name, 
    CONCAT(s.s_name, ' (', s.s_address, ')') AS supplier_info, 
    r.r_name AS region, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_quantity) AS total_quantity,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    MAX(l.l_shipdate) AS last_ship_date
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
    p.p_comment LIKE '%special%' AND 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address, r.r_name
ORDER BY 
    total_quantity DESC, part_name ASC;