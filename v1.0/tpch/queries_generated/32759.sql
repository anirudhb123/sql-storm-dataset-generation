WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal < 5000
),
AggregateData AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey
)
SELECT ns.n_name, 
       SUM(ads.avg_supplycost) AS total_avg_supplycost,
       COUNT(DISTINCT od.o_orderkey) AS total_orders,
       COUNT(sh.s_suppkey) AS total_suppliers,
       CASE 
           WHEN SUM(ads.avg_supplycost) > 10000 THEN 'High'
           WHEN SUM(ads.avg_supplycost) BETWEEN 5000 AND 10000 THEN 'Medium'
           ELSE 'Low' 
       END AS cost_category
FROM nation ns
LEFT JOIN AggregateData ads ON ns.n_nationkey = ads.p_partkey
LEFT JOIN OrderDetails od ON od.total_sales > 5000
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = ns.n_nationkey
GROUP BY ns.n_name
HAVING total_orders > 5
ORDER BY total_avg_supplycost DESC;
