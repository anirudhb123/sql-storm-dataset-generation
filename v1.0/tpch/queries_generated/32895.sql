WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 as Level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
RegionStats AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT(n.n_nationkey)) AS nation_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000 OR c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey, c.c_name
)
SELECT rs.r_name, rs.nation_count, rs.total_acctbal,
       COALESCE(cos.order_count, 0) AS customer_orders,
       cos.total_spent,
       sh.Level
FROM RegionStats rs
LEFT JOIN CustomerOrderStats cos ON rs.nation_count = cos.order_count
LEFT JOIN SupplierHierarchy sh ON rs.nation_count = sh.Level
WHERE rs.total_acctbal > 10000
ORDER BY rs.total_acctbal DESC, rs.r_name ASC;
