WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
AvgSupplierCost AS (
    SELECT ps_partkey,
           AVG(ps_supplycost) AS avg_cost
    FROM partsupp
    GROUP BY ps_partkey
),
TopRegions AS (
    SELECT r.r_name, 
           SUM(p.p_retailprice) AS total_retail,
           RANK() OVER (ORDER BY SUM(p.p_retailprice) DESC) AS region_rank
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY r.r_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 10
)
SELECT c.c_name,
       c.c_acctbal,
       ph.level AS supplier_level,
       tr.total_retail,
       CAST(COALESCE(NULLIF(SUM(l.l_extendedprice * (1 - l.l_discount)), 0), 0) AS DECIMAL(12, 2)) AS total_sales,
       RANK() OVER (PARTITION BY tr.region_rank ORDER BY total_sales DESC) AS sales_rank
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN SupplierHierarchy ph ON c.c_nationkey = ph.s_nationkey
JOIN TopRegions tr ON ph.s_nationkey = tr.r_name
WHERE o.o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE
GROUP BY c.c_name, c.c_acctbal, ph.level, tr.total_retail
ORDER BY total_sales DESC
LIMIT 100;
