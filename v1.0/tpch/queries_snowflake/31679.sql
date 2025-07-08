WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 5000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           COUNT(DISTINCT o.o_custkey) AS customer_count,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_total
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS unique_customers, 
       MAX(os.total_sales) AS max_sales, 
       AVG(ss.sales_total) AS average_supplier_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
LEFT JOIN SupplierSales ss ON c.c_nationkey = ss.s_suppkey
WHERE r.r_name LIKE 'E%' 
AND (c.c_acctbal IS NOT NULL OR c.c_mktsegment = 'CONSUMER')
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY unique_customers DESC;
