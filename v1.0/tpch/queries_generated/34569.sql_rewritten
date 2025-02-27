WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),

RegionStats AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),

HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate > '1997-01-01' AND (o.o_orderstatus IS NULL OR o.o_orderstatus <> 'C')
)

SELECT r.r_name, rs.supplier_count, rs.total_acctbal,
       COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count,
       AVG(l.l_extendedprice) AS avg_extended_price,
       MAX(coalesce(l.l_discount, 0) * l.l_extendedprice) AS max_discounted_price
FROM RegionStats rs
LEFT JOIN lineitem l ON l.l_extendedprice > (SELECT AVG(l_extendedprice) FROM lineitem)
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = l.l_orderkey
JOIN region r ON r.r_regionkey = rs.r_regionkey
GROUP BY r.r_name, rs.supplier_count, rs.total_acctbal
HAVING COUNT(DISTINCT hvo.o_orderkey) > 5
ORDER BY total_acctbal DESC, high_value_order_count DESC;