WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 10000 AND ch.level < 3
),
SupplierCosts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(CASE WHEN l.l_linestatus = 'F' THEN 1 END) AS count_f,
           COUNT(CASE WHEN l.l_linestatus = 'O' THEN 1 END) AS count_o
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name, 
       SUM(COALESCE(s.total_cost, 0)) AS total_supplier_cost,
       COUNT(DISTINCT ch.c_custkey) AS customer_count,
       AVG(LS.total_price) AS avg_order_price,
       MAX(LS.total_price) AS max_order_price,
       MIN(LS.total_price) AS min_order_price
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierCosts sc ON s.s_suppkey = sc.ps_suppkey
LEFT JOIN CustomerHierarchy ch ON n.n_nationkey = ch.c_nationkey
LEFT JOIN LineItemSummary LS ON ch.c_custkey = LS.l_orderkey
WHERE r.r_name LIKE 'A%'
  AND (ch.c_acctbal IS NOT NULL OR s.s_acctbal < 100)
GROUP BY r.r_name
HAVING COUNT(DISTINCT ch.c_custkey) > 5
ORDER BY r.r_name;
