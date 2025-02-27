WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.acctbal
),
TotalSales AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, COALESCE(ts.total_sales, 0) AS total_sales
    FROM customer c
    LEFT JOIN TotalSales ts ON c.c_custkey = ts.o_custkey
),
SupplierStats AS (
    SELECT sh.s_nationkey, COUNT(DISTINCT sh.s_suppkey) AS supplier_count, 
           SUM(sh.s_acctbal) AS total_acctbal, 
           AVG(sh.s_acctbal) AS avg_acctbal
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
)
SELECT 
    r.r_name, 
    COALESCE(cs.total_sales, 0) AS customer_sales, 
    ss.supplier_count, 
    ss.total_acctbal,
    ss.avg_acctbal
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer_sales cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN supplier_stats ss ON n.n_nationkey = ss.s_nationkey
WHERE r.r_name IS NOT NULL AND (ss.total_acctbal > 10000 OR cs.total_sales > 500) 
ORDER BY r.r_name, customer_sales DESC, supplier_count DESC;
