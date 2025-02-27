WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS VARCHAR(255)) AS full_path,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, s2.s_acctbal,
           CONCAT(sh.full_path, ' -> ', s2.s_name),
           sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s2.s_nationkey
    WHERE sh.level < 5
), OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY o.o_orderkey
), HighValueOrders AS (
    SELECT o.o_orderkey, os.total_revenue, os.distinct_parts
    FROM OrderStats os
    JOIN orders o ON os.o_orderkey = o.o_orderkey
    WHERE os.total_revenue > (SELECT AVG(total_revenue) FROM OrderStats)
)
SELECT nh.n_name AS nation_name, 
       COUNT(DISTINCT hv.o_orderkey) AS high_value_order_count,
       AVG(hv.total_revenue) AS avg_revenue,
       STRING_AGG(DISTINCT sh.full_path, '; ') AS supplier_paths
FROM HighValueOrders hv
JOIN customer c ON hv.o_orderkey = c.c_custkey
JOIN nation nh ON c.c_nationkey = nh.n_nationkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = c.c_nationkey
GROUP BY nh.n_name
ORDER BY high_value_order_count DESC;
