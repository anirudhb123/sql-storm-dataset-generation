WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
    WHERE ch.level < 5
),
SupplierSummary AS (
    SELECT s.s_nationkey, AVG(s.s_acctbal) AS avg_acctbal, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    GROUP BY s.s_nationkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value, COUNT(*) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey
)
SELECT 
    n.n_name,
    SUM(COALESCE(od.total_value, 0)) AS total_order_value,
    ss.avg_acctbal,
    ss.supplier_count,
    COUNT(DISTINCT ch.c_custkey) AS loyal_customers,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(COALESCE(od.total_value, 0)) DESC) AS nation_rank
FROM nation n
LEFT JOIN SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN OrderDetails od ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part)))
LEFT JOIN CustomerHierarchy ch ON ch.c_nationkey = n.n_nationkey
GROUP BY n.n_name, ss.avg_acctbal, ss.supplier_count
HAVING total_order_value > 5000 AND ss.avg_acctbal IS NOT NULL
ORDER BY nation_rank;
