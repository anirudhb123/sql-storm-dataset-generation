SELECT 
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(p.p_retailprice) AS average_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
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
    r.r_name LIKE '%West%'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    supplier_info, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, average_price ASC;