WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
), part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           COUNT(DISTINCT s.s_suppkey) OVER (PARTITION BY ps.ps_partkey) AS supp_count,
           SUM(CASE WHEN ps.ps_supplycost IS NULL THEN 0 ELSE ps.ps_supplycost END) OVER (PARTITION BY ps.ps_partkey) AS total_supply_cost
    FROM partsupp ps
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS lineitem_count, 
           STRING_AGG(DISTINCT l.l_shipmode, ', ') AS shipping_modes
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
), ranked_orders AS (
    SELECT os.o_orderkey, os.total_revenue,
           RANK() OVER (PARTITION BY os.lineitem_count ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM order_summary os
), regional_revenue AS (
    SELECT r.r_name, COUNT(DISTINCT os.o_orderkey) AS order_count,
           SUM(os.total_revenue) AS total_revenue
    FROM region r
    LEFT JOIN customer c ON r.r_regionkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN order_summary os ON o.o_orderkey = os.o_orderkey
    GROUP BY r.r_name
)
SELECT p.p_name, p.p_brand, p.p_mfgr, ps.ps_availqty, 
       CASE 
           WHEN ps.ps_supplycost IS NULL THEN 'Cost Unavailable' 
           ELSE FORMAT(ps.ps_supplycost, 'C') 
       END AS formatted_supplycost,
       COALESCE(r.revenue_rank, 0) AS order_rank,
       nh.level AS nation_level, rr.total_revenue,
       rr.order_count,
       (SELECT COUNT(*) FROM lineitem ll WHERE ll.l_orderkey IN (SELECT o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')) AS total_filled_orders,
       (SELECT COUNT(DISTINCT s.s_nationkey) FROM supplier s) AS distinct_suppress
FROM part_supplier ps
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN ranked_orders r ON ps.ps_partkey = r.o_orderkey
JOIN nation_hierarchy nh ON nh.n_nationkey = p.p_partkey
LEFT JOIN regional_revenue rr ON rr.order_count > 10
WHERE p.p_size BETWEEN 10 AND 20
ORDER BY p.p_retailprice DESC, nh.level;
