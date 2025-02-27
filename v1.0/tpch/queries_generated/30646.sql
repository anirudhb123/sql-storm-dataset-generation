WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND sh.level < 5
),
TotalSales AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY c.c_custkey
),
RankedSales AS (
    SELECT c.c_custkey, ts.total_sales,
           RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM TotalSales ts
    JOIN customer c ON ts.c_custkey = c.c_custkey
)
SELECT ph.p_partkey, ph.p_name, s.s_name AS supplier_name, ts.total_sales, 
       COALESCE(r.sales_rank, 0) AS customer_rank, 
       (s.s_acctbal * 0.1) AS projected_value,
       CASE 
           WHEN r.sales_rank IS NULL THEN 'No Sales'
           WHEN r.total_sales > 1000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS customer_status
FROM part ph
LEFT JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN RankedSales r ON s.s_nationkey = r.c_custkey
WHERE ph.p_retailprice >= 100 AND (s.s_acctbal IS NOT NULL OR s.s_acctbal > 500)
ORDER BY total_sales DESC NULLS LAST, supplier_name;
