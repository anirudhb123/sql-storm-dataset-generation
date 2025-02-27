SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS consolidated_comments
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
    LENGTH(p.p_name) > 10 
    AND s.s_acctbal > 5000
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, n.n_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_orders DESC, total_quantity DESC;
