
WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate,
           o_orderpriority, o_clerk, o_shippriority, o_comment, 0 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           o.o_orderpriority, o.o_clerk, o.o_shippriority, o.o_comment, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
),
OrderedLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS line_item_count, AVG(l.l_quantity) AS avg_quantity,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           SUM(COALESCE(ps.ps_supplycost, 0)) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty
)
SELECT 
    o.o_orderkey,
    oh.level,
    cl.c_name,
    COUNT(DISTINCT l.l_partkey) AS unique_parts_count,
    SUM(ol.total_revenue) AS order_revenue,
    AVG(sp.total_supplycost) AS avg_supply_cost_per_part
FROM OrderHierarchy oh
JOIN orders o ON o.o_orderkey = oh.o_orderkey
JOIN customer cl ON o.o_custkey = cl.c_custkey
LEFT JOIN OrderedLineItems ol ON o.o_orderkey = ol.l_orderkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierParts sp ON sp.ps_partkey = l.l_partkey
GROUP BY o.o_orderkey, oh.level, cl.c_name
HAVING SUM(ol.total_revenue) > 1000
ORDER BY unique_parts_count DESC, order_revenue DESC
LIMIT 50;
