WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
HighValueLines AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           CASE 
               WHEN l.l_discount > 0.1 THEN 'High Discount'
               ELSE 'Regular'
           END AS discount_category
    FROM lineitem l
    WHERE l.l_quantity > (SELECT AVG(l2.l_quantity) FROM lineitem l2)
),
SupplierAggregates AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT n.n_name, r.r_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
       COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance,
       AVG(hl.l_extendedprice) AS avg_line_price,
       MAX(hl.l_extendedprice) AS max_line_price
FROM nation n
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN RankedOrders o ON o.o_orderkey IN (SELECT l.l_orderkey FROM HighValueLines hl WHERE hl.l_partkey = o.o_orderkey)
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierAggregates sa ON sa.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_orders DESC, total_supplier_balance DESC

