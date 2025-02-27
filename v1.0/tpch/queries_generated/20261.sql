WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0 
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = o.o_orderkey) AS item_count,
           DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND 
          o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
), 
CustomerPreferences AS (
    SELECT DISTINCT c.c_custkey, c.c_mktsegment,
           COUNT(CASE WHEN o.o_orderstatus = 'O' THEN 1 END) AS active_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
)
SELECT r.s_name, r.total_supply_cost, r.rank,
       COALESCE(cp.active_orders, 0) AS active_orders,
       SUM(CASE 
               WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice * (1 - lo.l_discount)
               ELSE 0 
           END) AS total_returned_value,
       MAX(o.o_totalprice) AS max_order_value
FROM RankedSuppliers r
LEFT JOIN RecentOrders o ON r.s_suppkey = o.o_custkey 
LEFT JOIN lineitem lo ON o.o_orderkey = lo.l_orderkey
LEFT JOIN CustomerPreferences cp ON o.o_custkey = cp.c_custkey
GROUP BY r.s_name, r.total_supply_cost, r.rank, cp.active_orders
HAVING SUM(lo.l_quantity) > 100 AND
       COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY r.rank, total_supply_cost DESC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM supplier WHERE s_comment IS NOT NULL) / 2;
