SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(CONCAT(o.o_orderdate, ' - ', o.o_orderstatus), '; ') AS order_dates_statuses
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
WHERE 
    s.s_acctbal > 10000
    AND l.l_shipdate >= '1997-01-01'
    AND o.o_orderstatus IN ('O', 'F')
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(l.l_quantity) > 50
ORDER BY 
    total_revenue DESC, total_orders DESC;