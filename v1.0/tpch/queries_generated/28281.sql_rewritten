SELECT 
    p.p_name, 
    COUNT(l.l_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    AVG(l.l_quantity) AS average_quantity, 
    MAX(s.s_acctbal) AS max_supplier_balance,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    customer c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%special%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name
HAVING 
    COUNT(l.l_orderkey) > 10
ORDER BY 
    total_revenue DESC
LIMIT 100;