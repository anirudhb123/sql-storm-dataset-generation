
SELECT 
    CONCAT('Supplier: ', s_name, 
           ' | Part Name: ', p_name, 
           ' | Total Price: ', SUM(l_extendedprice * (1 - l_discount)), 
           ' | Region: ', r_name) AS benchmark_info
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l_shipdate >= '1997-01-01' 
    AND l_shipdate <= '1997-12-31'
GROUP BY 
    s_name, p_name, r_name
HAVING 
    SUM(l_extendedprice * (1 - l_discount)) > 10000
ORDER BY 
    SUM(l_extendedprice * (1 - l_discount)) DESC;
