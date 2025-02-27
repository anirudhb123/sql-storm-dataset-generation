SELECT 
    p.p_name, 
    s.s_name,
    n.n_name,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    STRING_AGG(DISTINCT o.o_orderpriority, ', ') AS order_priorities
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
    p.p_name LIKE '%widget%' 
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name
HAVING 
    SUM(l.l_extendedprice) > 10000
ORDER BY 
    total_revenue DESC, total_orders DESC;