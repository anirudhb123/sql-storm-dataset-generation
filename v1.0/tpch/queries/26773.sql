SELECT 
    CONCAT(c.c_name, ' (', n.n_name, ')') AS customer_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' [', ps.ps_supplycost, ']'), ', ') AS supplied_parts,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= '1997-01-01' 
GROUP BY 
    c.c_custkey, c.c_name, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;