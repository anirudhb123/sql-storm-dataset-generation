SELECT 
    p.p_name,
    s.s_name,
    n.n_name,
    r.r_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Nation: ', n.n_name, ', Region: ', r.r_name) AS full_description,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS aggregated_comments,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price_per_item
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
    p.p_type LIKE '%metal%' 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name
ORDER BY 
    total_orders DESC, avg_price_per_item DESC;