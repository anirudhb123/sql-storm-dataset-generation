SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' [', s.s_nationkey, ']'), '; ') AS suppliers
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND l.l_shipdate >= DATE '1996-01-01'
    AND l.l_shipdate <= DATE '1996-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;