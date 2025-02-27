WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.o_custkey, level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND oh.o_orderdate < o.o_orderdate
)
SELECT 
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(revenue_by_order) AS average_revenue_per_order,
    RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = c.c_nationkey AND n.n_name != 'USA')
    AND (o.o_orderdate BETWEEN '2022-01-01' AND '2023-12-31')
GROUP BY 
    c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000.00
ORDER BY 
    total_revenue DESC
LIMIT 10;
