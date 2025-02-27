SELECT 
    CONCAT_WS(' - ', 
        SUBSTRING(p_name, 1, 10), 
        REPLACE(s_name, 'Supplier', ''), 
        LEFT(c_address, 15), 
        r_name,
        DATE_FORMAT(o_orderdate, '%Y-%m-%d')
    ) AS benchmark_string,
    COUNT(DISTINCT o_orderkey) AS order_count,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r_name LIKE 'Europe%' 
    AND o_orderstatus = 'O'
GROUP BY 
    benchmark_string
ORDER BY 
    total_revenue DESC
LIMIT 100;
