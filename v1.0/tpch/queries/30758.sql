
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND s.s_suppkey <> sh.s_suppkey
),

PartSupplierCounts AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

RegionStats AS (
    SELECT r.r_regionkey, r.r_name, SUM(s.s_acctbal) AS total_acctbal, COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),

MaxOrderTotals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),

FinalResults AS (
    SELECT r.r_name, rs.total_acctbal, rs.total_suppliers, MAX(m.total_order_amount) AS max_order_amount
    FROM RegionStats rs
    JOIN region r ON rs.r_regionkey = r.r_regionkey
    LEFT JOIN MaxOrderTotals m ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        WHERE n.n_nationkey IN (
            SELECT DISTINCT s.s_nationkey 
            FROM supplier s 
            WHERE s.s_suppkey IN (
                SELECT DISTINCT sh.s_suppkey 
                FROM SupplierHierarchy sh
            )
        )
    )
    GROUP BY r.r_name, rs.total_acctbal, rs.total_suppliers
)

SELECT f.r_name, f.total_acctbal, f.total_suppliers, f.max_order_amount, 
       CASE 
           WHEN f.total_suppliers IS NULL THEN 'No suppliers'
           WHEN f.max_order_amount IS NULL THEN 'No orders'
           ELSE 'Data available'
       END AS status
FROM FinalResults f
ORDER BY f.total_acctbal DESC, f.max_order_amount DESC;
