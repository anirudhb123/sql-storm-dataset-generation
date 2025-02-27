WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level 
    FROM supplier s
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 500
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_sold,
    CASE 
        WHEN SUM(l.l_tax) IS NULL THEN 0 
        ELSE SUM(l.l_tax) 
    END AS total_tax,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice) DESC) AS rank
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
WHERE o.o_orderstatus = 'F' 
AND l.l_shipdate >= DATE '1997-01-01' 
AND l.l_shipdate < DATE '1998-01-01' 
AND l.l_discount BETWEEN 0.05 AND 0.20
GROUP BY n.n_nationkey, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 50
ORDER BY total_revenue DESC;