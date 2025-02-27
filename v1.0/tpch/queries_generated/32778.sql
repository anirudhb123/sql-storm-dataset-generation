WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS order_level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
),
SupplierStats AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_avail_qty, 
           MAX(ps.ps_supplycost) AS max_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SalesData AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_orderkey, l.l_partkey
),
CombinedResults AS (
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, sd.revenue,
           s.supplier_count, s.total_avail_qty, s.max_supply_cost
    FROM OrderHierarchy oh
    LEFT JOIN SalesData sd ON oh.o_orderkey = sd.l_orderkey
    LEFT JOIN SupplierStats s ON sd.l_partkey = s.ps_partkey
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(cr.o_totalprice) AS avg_order_value, 
       SUM(cr.revenue) AS total_revenue,
       MAX(cr.max_supply_cost) AS highest_supply_cost
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN CombinedResults cr ON cr.supplier_count > 0
JOIN customer c ON c.c_nationkey = n.n_nationkey
WHERE cr.o_orderdate IS NOT NULL
GROUP BY r.r_name
HAVING SUM(cr.total_revenue) > 100000
ORDER BY avg_order_value DESC;
