WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_supplycost, ps_partkey, s_nationkey, s_suppkey, 1 AS level
    FROM partsupp
    JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
    WHERE ps_availqty > 0
    UNION ALL
    SELECT sh.s_supplycost, ps.partkey, sh.s_nationkey, ps.s_suppkey, level + 1
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.ps_partkey = ps.ps_partkey
    WHERE sh.level < 5
),
FilteredOrders AS (
    SELECT o_orderkey, o_totalprice, o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS order_rank
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
),
AggregatedLineItems AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
           COUNT(*) AS line_count,
           MAX(l_shipmode) AS popular_mode
    FROM lineitem
    GROUP BY l_orderkey
)
SELECT n.n_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(coalesce(sh.s_supplycost, 0)) AS total_supply_cost,
       AVG(a.total_sales) AS average_sales,
       ARRAY_AGG(DISTINCT a.popular_mode) AS popular_modes,
       CASE 
           WHEN COUNT(DISTINCT a.line_count) > 0 THEN 'Line items present'
           ELSE 'No line items'
       END AS line_item_status
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN FilteredOrders fo ON c.c_custkey = fo.o_custkey
LEFT JOIN AggregatedLineItems a ON fo.o_orderkey = a.l_orderkey
LEFT JOIN SupplierHierarchy sh ON a.l_orderkey = sh.ps_partkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING SUM(a.total_sales) > 1000
ORDER BY customer_count DESC, average_sales DESC;
