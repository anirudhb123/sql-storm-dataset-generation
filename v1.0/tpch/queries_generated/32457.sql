WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > (ch.c_acctbal * 0.75)
),
SupplierStatistics AS (
    SELECT s_nationkey, COUNT(DISTINCT s_suppkey) AS total_suppliers,
           SUM(s_acctbal) AS total_acctbal, AVG(s_acctbal) AS avg_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
OrderLineSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT n.n_name, 
       COALESCE(cs.total_suppliers, 0) AS total_suppliers,
       COALESCE(cs.total_acctbal, 0) AS total_acctbal,
       COALESCE(cs.avg_acctbal, 0) AS avg_acctbal,
       SUM(ols.net_revenue) AS total_revenue,
       COUNT(DISTINCT ch.c_custkey) AS customer_count,
       MAX(ch.level) AS max_hierarchy_level
FROM nation n
LEFT JOIN SupplierStatistics cs ON n.n_nationkey = cs.s_nationkey
LEFT JOIN OrderLineSummary ols ON ols.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_nationkey = n.n_nationkey
)
LEFT JOIN CustomerHierarchy ch ON ch.c_nationkey = n.n_nationkey
GROUP BY n.n_nationkey, n.n_name
ORDER BY total_revenue DESC, n.n_name;
