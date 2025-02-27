WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
LineitemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS line_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
    GROUP BY l.l_orderkey
),
SummaryStats AS (
    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        oh.o_totalprice,
        la.total_revenue,
        la.line_count,
        la.avg_quantity,
        COALESCE(ss.total_supply_value, 0) AS total_supply_value
    FROM OrderHierarchy oh
    LEFT JOIN LineitemAggregates la ON oh.o_orderkey = la.l_orderkey
    LEFT JOIN SupplierStats ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = oh.o_orderkey LIMIT 1)
    )
)
SELECT 
    COALESCE(r.r_name, 'Unknown') AS region_name,
    n.n_name AS nation_name,
    SUM(ss.total_revenue) AS total_order_revenue,
    AVG(ss.avg_quantity) AS avg_order_quantity,
    COUNT(DISTINCT ss.o_orderkey) AS total_orders
FROM SummaryStats ss
JOIN customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ss.o_orderkey LIMIT 1)
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE ss.total_supply_value > 1000
GROUP BY r.r_name, n.n_name
ORDER BY total_order_revenue DESC, avg_order_quantity ASC
LIMIT 50;
