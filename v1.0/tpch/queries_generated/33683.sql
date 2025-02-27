WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
RichRegion AS (
    SELECT r.r_regionkey, r.r_name, SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING SUM(s.s_acctbal) > 100000
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT sr.s_name, sr.level, rr.r_name, SUM(os.total_order_value) AS total_revenue, 
       COUNT(DISTINCT os.o_orderkey) AS unique_orders
FROM SupplierHierarchy sr
JOIN RichRegion rr ON sr.s_nationkey = rr.r_regionkey
LEFT JOIN OrderSummary os ON os.o_custkey = sr.s_suppkey
WHERE sr.level BETWEEN 1 AND 2
GROUP BY sr.s_name, sr.level, rr.r_name
ORDER BY total_revenue DESC, sr.s_name
LIMIT 10;
