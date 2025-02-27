SELECT 
    n.n_name AS nation_name, 
    COUNT(DISTINCT c.c_custkey) AS total_customers, 
    SUM(CASE 
            WHEN o.o_orderstatus = 'O' 
            THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts
FROM 
    nation n 
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
WHERE 
    n.r_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA') 
GROUP BY 
    n.n_name 
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5 
ORDER BY 
    total_revenue DESC;
