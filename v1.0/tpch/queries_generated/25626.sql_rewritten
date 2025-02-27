SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(CAST(l.l_extendedprice AS DECIMAL(14, 2))) AS avg_extended_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%special%' AND
    o.o_orderdate >= DATE '1997-01-01' AND 
    o.o_orderdate < DATE '1997-12-31'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;