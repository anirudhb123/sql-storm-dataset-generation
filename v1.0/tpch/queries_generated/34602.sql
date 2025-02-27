WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate, o_orderpriority, o_clerk, o_shippriority, o_comment, 1 AS Level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority, o.o_clerk, o.o_shippriority, o.o_comment, oh.Level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
    WHERE o.o_orderstatus = 'O'
),
SupplierStatistics AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT oh.o_orderkey, oh.o_orderdate, oo.supply_count, oo.total_cost
    FROM OrderHierarchy oh
    LEFT JOIN (
        SELECT l.l_orderkey, COUNT(DISTINCT l.l_partkey) AS supply_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
        FROM lineitem l
        GROUP BY l.l_orderkey
    ) oo ON oh.o_orderkey = oo.l_orderkey
)
SELECT
    r.r_name,
    SUM(os.total_cost) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(ps.avg_supply_cost) AS average_supply_cost,
    (SELECT COUNT(DISTINCT n.n_nationkey) FROM nation n WHERE n.n_regionkey = r.r_regionkey) AS nation_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN SupplierStatistics ps ON ps.s_suppkey IN (SELECT ps.s_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey))
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING total_revenue > 1000000
ORDER BY total_revenue DESC;
