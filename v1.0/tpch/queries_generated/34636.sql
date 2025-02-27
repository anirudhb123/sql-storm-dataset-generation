WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND sh.level < 5
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING SUM(s.s_acctbal) > 10000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FinalResult AS (
    SELECT c.c_name, r.r_name, COALESCE(ls.total_line_price, 0) AS total_value,
           DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY COALESCE(ls.total_line_price, 0) DESC) AS rank_value
    FROM CustomerOrders c
    JOIN region r ON r.r_regionkey IN (SELECT DISTINCT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey)
    LEFT JOIN LineItemSummary ls ON c.c_custkey = ls.l_orderkey
    WHERE c.order_count > 0
)
SELECT f.c_name, f.r_name, f.total_value
FROM FinalResult f
WHERE f.rank_value <= 10
ORDER BY f.r_name, f.total_value DESC;
