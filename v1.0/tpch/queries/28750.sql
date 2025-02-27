SELECT 
    p.p_name, 
    s.s_name, 
    SUBSTRING(s.s_address, 1, 30) AS short_address,
    CONCAT(s.s_name, ' from ', r.r_name) AS supplier_region,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS aggregated_comments
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
    p.p_size > 10 
    AND s.s_acctbal > 1000.00 
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, short_address, supplier_region
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 100;
