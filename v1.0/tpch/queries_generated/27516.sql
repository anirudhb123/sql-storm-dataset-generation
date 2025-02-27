SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT('Total revenue for ', p.p_name, ' is $', 
           FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS revenue_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    p.p_name LIKE '%widget%'
    AND o.o_orderdate >= '2023-01-01'
    AND o.o_orderdate < '2023-12-31'
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_name
HAVING 
    total_quantity > 500
ORDER BY 
    total_revenue DESC;
