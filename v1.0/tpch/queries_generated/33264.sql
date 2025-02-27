WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal - COALESCE(NULLIF(s_acctbal, 0), 1))
                        FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TotalSales AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, t.total_sales,
           RANK() OVER (ORDER BY t.total_sales DESC) AS sales_rank
    FROM customer c
    JOIN TotalSales t ON c.c_custkey = t.o_custkey
),
RegionSummary AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT r.r_name, rs.supplier_count, rs.total_avail_qty,
       COALESCE(tc.total_sales, 0) AS total_sales,
       sh.s_name AS supplier_name,
       sh.s_acctbal AS supplier_acctbal
FROM RegionSummary rs
LEFT JOIN TopCustomers tc ON rs.supplier_count = (SELECT COUNT(*) FROM SupplierHierarchy WHERE level < 5)
LEFT JOIN SupplierHierarchy sh ON rs.supplier_count > 0
WHERE rs.total_avail_qty > 1000
ORDER BY rs.supplier_count DESC, tc.total_sales DESC;
