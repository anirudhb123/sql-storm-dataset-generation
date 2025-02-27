WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'Europe')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_nationkey
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
lineitem_summary AS (
    SELECT l.l_orderkey, COUNT(*) AS line_item_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT n.n_name,
       ss.s_name,
       COUNT(DISTINCT lo.l_orderkey) AS order_count,
       SUM(los.line_item_count) AS total_line_items,
       AVG(ls.avg_supply_cost) AS avg_supply_cost,
       MAX(lo.total_revenue) AS max_revenue
FROM nation_hierarchy n
JOIN supplier_summary ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN ranked_orders lo ON ss.s_suppkey = lo.o_custkey
JOIN lineitem_summary los ON lo.o_orderkey = los.l_orderkey
GROUP BY n.n_name, ss.s_name
HAVING COUNT(DISTINCT lo.o_orderkey) > 5
ORDER BY MAX(lo.total_revenue) DESC NULLS LAST;
