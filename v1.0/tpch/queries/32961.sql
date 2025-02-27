
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), 
PartStatistics AS (
    SELECT p.p_partkey, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           MAX(ps.ps_availqty) AS max_avail_qty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderDetails AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY o.o_orderkey
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(ps.avg_supply_cost) AS total_supply_cost,
       SUM(ods.total_sales) AS total_order_sales,
       AVG(ods.unique_parts) AS avg_unique_parts_per_order,
       COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END), 0) AS total_returns
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN PartStatistics ps ON ps.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE '%PAPER%')
LEFT JOIN OrderDetails ods ON c.c_custkey = ods.o_orderkey
LEFT JOIN lineitem l ON ods.o_orderkey = l.l_orderkey
WHERE c.c_acctbal IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 
   AND SUM(ps.avg_supply_cost) IS NOT NULL
ORDER BY total_order_sales DESC;
