WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 1 AS level
    FROM supplier s
    WHERE s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_availqty > 100
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = 'USA'
    ) 
)

SELECT 
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_ship_date,
    ROW_NUMBER() OVER (PARTITION BY c.c_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
WHERE 
    o.o_orderstatus = 'F'
    AND l.l_shipdate >= DATE '2023-01-01'
    AND sh.level IS NOT NULL
GROUP BY 
    c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
