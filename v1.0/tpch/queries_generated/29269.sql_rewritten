SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
    MIN(s.s_acctbal) AS min_supplier_balance,
    MAX(s.s_acctbal) AS max_supplier_balance,
    AVG(l.l_quantity) AS avg_lineitem_quantity,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_brand LIKE '%Brand%' 
    AND c.c_mktsegment = 'AUTO'
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name
ORDER BY 
    total_revenue DESC 
LIMIT 100;