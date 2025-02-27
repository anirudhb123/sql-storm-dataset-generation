
SELECT 
    CONCAT(SUBSTRING(p.p_name, 1, 20), '...', p.p_retailprice) AS truncated_part_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_acctbal, ')'), '; ') AS customer_list
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 100
    AND l.l_shipdate >= DATE '1997-01-01' 
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, p.p_retailprice, s.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
