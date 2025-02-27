WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
RegionalSales AS (
    SELECT n.n_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
      AND l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY n.n_name
),
SupplierRankings AS (
    SELECT sh.s_suppkey, 
           sh.s_name, 
           DENSE_RANK() OVER (PARTITION BY sh.level ORDER BY sh.s_acctbal DESC) AS rank
    FROM SupplierHierarchy sh
)
SELECT r.n_name,
       r.total_sales,
       r.order_count,
       sr.s_name AS top_supplier,
       sr.rank
FROM RegionalSales r
LEFT JOIN SupplierRankings sr ON r.order_count = (SELECT MAX(order_count) FROM RegionalSales)
ORDER BY r.total_sales DESC, r.n_name;
