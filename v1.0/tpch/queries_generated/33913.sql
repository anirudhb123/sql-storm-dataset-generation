WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
  UNION ALL
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
),
LineItemSummary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(*) AS item_count,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierStats AS (
    SELECT s.s_suppkey,
           AVG(ps.ps_supplycost) AS avg_supplycost,
           SUM(ps.ps_availqty) AS total_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerSegmentation AS (
    SELECT c.c_custkey,
           c.c_mktsegment,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
)
SELECT COALESCE(cs.c_mktsegment, 'UNKNOWN') AS segment,
       SUM(cs.order_count) AS total_orders,
       COUNT(DISTINCT cs.c_custkey) AS unique_customers,
       MAX(lis.total_price) AS max_order_value,
       AVG(ss.avg_supplycost) AS avg_supply_cost
FROM CustomerSegmentation cs
LEFT JOIN LineItemSummary lis ON cs.order_count > 0
LEFT JOIN SupplierStats ss ON ss.avg_supplycost IS NOT NULL
GROUP BY cs.c_mktsegment
HAVING COUNT(DISTINCT cs.c_custkey) > 1
ORDER BY max_order_value DESC
LIMIT 10;
