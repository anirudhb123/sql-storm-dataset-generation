WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey AS order_key, o.o_orderdate AS order_date, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.order_key, o.o_orderdate, oh.order_level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.order_key = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
LineItemSummary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS total_items
    FROM lineitem l
    WHERE l.l_shipdate >= '2021-01-01' AND l.l_shipdate <= '2021-12-31'
    GROUP BY l.l_orderkey
),
SupplierPerformance AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT r.r_name AS region_name,
       n.n_name AS nation_name,
       p.p_name AS part_name,
       COALESCE(SUM(LIS.total_revenue), 0) AS total_order_revenue,
       COALESCE(SUM(SUP.total_available), 0) AS total_available_from_supplier,
       MAX(SUP.avg_supply_cost) AS max_supply_cost,
       COUNT(DISTINCT O.order_key) AS order_count,
       MAX(O.order_level) AS max_order_level
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN LineItemSummary LIS ON LIS.l_orderkey = ps.ps_partkey
LEFT JOIN OrderHierarchy O ON O.order_key = LIS.l_orderkey
GROUP BY r.r_name, n.n_name, p.p_name
HAVING SUM(LIS.total_revenue) > 100000
ORDER BY total_order_revenue DESC, region_name, nation_name, part_name;
