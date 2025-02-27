SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names,
    MAX(l.l_discount) AS highest_discount,
    MIN(l.l_extendedprice) AS lowest_price
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
    p.p_name LIKE '%widget%' 
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    AND l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, p.p_name;