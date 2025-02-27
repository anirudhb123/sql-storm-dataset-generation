SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    SUM(l.l_quantity) AS total_quantity,
    MAX(l.l_tax) AS max_tax_rate,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
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
    p.p_comment LIKE '%special%'
    AND s.s_comment NOT LIKE '%regular%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_price_after_discount DESC, total_quantity DESC;