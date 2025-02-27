WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE sh.level < 5
),
AvgPrices AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 500000
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(a.avg_supplycost) AS average_supply_cost,
    SUM(CASE WHEN h.total_revenue IS NOT NULL THEN h.total_revenue ELSE 0 END) AS total_revenue_from_high_value_orders,
    COUNT(DISTINCT sh.s_suppkey) AS active_suppliers
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN AvgPrices a ON a.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000.00
)
LEFT JOIN HighValueOrders h ON h.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > '2023-01-01'
)
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.n_nationkey
GROUP BY n.n_name
ORDER BY n.n_name;
