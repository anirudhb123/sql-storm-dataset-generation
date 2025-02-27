WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_suppkey = 1
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
RegionalSuppliers AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, os.total_sales
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE os.sales_rank <= 10
),
PopularParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_quantity) > 100
)
SELECT DISTINCT r.r_name, sh.level, p.p_name, cs.total_sales
FROM RegionalSuppliers r
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = r.r_regionkey)
JOIN PopularParts p ON sh.s_suppkey = p.p_partkey
JOIN CustomerSales cs ON cs.c_custkey = sh.s_suppkey
WHERE cs.total_sales IS NOT NULL OR r.supplier_count > 5
ORDER BY r.r_name, sh.level, cs.total_sales DESC;
