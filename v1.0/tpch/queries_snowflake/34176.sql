WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, SUM(ts.total_price) AS customer_total
    FROM customer c
    LEFT JOIN TotalSales ts ON c.c_custkey = ts.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
RegionWiseSupplier AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
FinalReport AS (
    SELECT cs.c_name, cs.customer_total, rh.r_name, rh.supplier_count
    FROM CustomerSales cs
    JOIN RegionWiseSupplier rh ON cs.customer_total > (SELECT AVG(customer_total) FROM CustomerSales)
)
SELECT fr.c_name, fr.customer_total, fr.r_name, fr.supplier_count,
       RANK() OVER (PARTITION BY fr.r_name ORDER BY fr.customer_total DESC) AS sales_rank,
       CASE WHEN fr.customer_total IS NULL THEN 'No Sales' ELSE 'Sales Exist' END AS sales_status
FROM FinalReport fr
WHERE fr.supplier_count > 0
ORDER BY fr.r_name, fr.customer_total DESC;
