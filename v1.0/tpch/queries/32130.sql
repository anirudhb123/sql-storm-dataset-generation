WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS lvl
    FROM orders o
    WHERE o.o_orderstatus = 'O' 
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.lvl + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate < oh.o_orderdate
), SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost,
           AVG(ps.ps_availqty) AS avg_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), LineItemSummary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS item_count,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01' 
    GROUP BY l.l_orderkey
)
SELECT r.r_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(l.total_revenue) AS total_revenue,
       AVG(sp.total_supply_cost) AS avg_supply_cost,
       MAX(sp.avg_avail_qty) AS max_avg_avail_qty
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN orders o ON ps.ps_partkey = o.o_orderkey
LEFT JOIN LineItemSummary l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_orders DESC, total_revenue DESC;