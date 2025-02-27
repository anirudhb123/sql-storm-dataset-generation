WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierWithDiscounts AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supply_cost,
           SUM(CASE WHEN l.l_discount > 0.1 THEN 1 ELSE 0 END) AS high_discount_supplies
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
)

SELECT r.r_name, 
       SUM(os.total_revenue) AS total_revenue,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       MAX(sd.avg_supply_cost) AS max_supply_cost,
       COUNT(*) FILTER (WHERE sd.high_discount_supplies > 0) AS suppliers_with_high_discounts
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN SupplierWithDiscounts sd ON sh.s_suppkey = sd.s_suppkey
WHERE o.o_orderstatus = 'O' 
AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY r.r_name
HAVING SUM(os.total_revenue) > 1000000
ORDER BY total_revenue DESC;