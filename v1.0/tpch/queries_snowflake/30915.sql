
WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_shippriority,
           0 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, o.o_shippriority,
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) > 100
),
LineItemDetails AS (
    SELECT l.l_orderkey, COUNT(DISTINCT l.l_partkey) AS part_count,
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
RankedOrders AS (
    SELECT oh.o_orderkey, oh.o_totalprice, oh.o_orderdate, l.part_count, 
           ROW_NUMBER() OVER (ORDER BY oh.o_totalprice DESC) AS order_rank
    FROM OrderHierarchy oh
    LEFT JOIN LineItemDetails l ON oh.o_orderkey = l.l_orderkey
)
SELECT ro.o_orderkey, ro.o_totalprice, ro.part_count, 
       COALESCE(SUM(ss.total_supply_cost), 0) AS total_supplier_cost,
       CASE 
           WHEN ro.part_count IS NULL THEN 'NO PRODUCTS'
           WHEN ro.part_count > 10 THEN 'HIGH VOLUME'
           ELSE 'REGULAR'
       END AS order_type
FROM RankedOrders ro
LEFT JOIN SupplierStats ss ON ro.o_orderkey = ss.s_suppkey
GROUP BY ro.o_orderkey, ro.o_totalprice, ro.part_count
ORDER BY ro.o_totalprice DESC
LIMIT 10;
