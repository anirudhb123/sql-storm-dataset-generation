WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartAnalysis AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
CustomerSummary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT c.c_custkey) AS total_customers, SUM(c.c_acctbal) AS total_acctbal
    FROM customer c
    GROUP BY c.c_nationkey
),
OrdersStatistics AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate > '1996-01-01'
)
SELECT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(l.l_orderkey) AS total_orders,
    COALESCE(sa.total_acctbal, 0) AS total_customer_acctbal,
    p.p_name AS part_name,
    p.avg_supplycost,
    COUNT(DISTINCT oi.o_orderkey) AS distinct_orders,
    SUM(oi.o_totalprice) AS total_order_value
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN PartAnalysis p ON l.l_partkey = p.p_partkey
LEFT JOIN CustomerSummary sa ON n.n_nationkey = sa.c_nationkey
LEFT JOIN OrdersStatistics oi ON oi.o_orderkey = l.l_orderkey AND oi.rn = 1
WHERE s.s_acctbal IS NOT NULL
GROUP BY r.r_name, n.n_name, s.s_name, p.p_name, p.avg_supplycost, sa.total_acctbal
HAVING SUM(l.l_quantity) > 1000
ORDER BY total_orders DESC, total_order_value DESC;