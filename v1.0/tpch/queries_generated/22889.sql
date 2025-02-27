WITH RECURSIVE region_summary AS (
    SELECT r_regionkey, r_name,
           (SELECT COUNT(DISTINCT n_nationkey) FROM nation WHERE n_regionkey = r_regionkey) AS nation_count
    FROM region
),
supplier_summary AS (
    SELECT s_nationkey, SUM(s_acctbal) AS total_acctbal,
           MAX(s_acctbal) AS max_acctbal, MIN(s_acctbal) AS min_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
part_availability AS (
    SELECT ps_partkey,
           SUM(ps_availqty) AS total_available_qty,
           SUM(ps_supplycost) AS total_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
),
customer_order_summary AS (
    SELECT c.c_custkey, 
           SUM(o.o_totalprice) AS total_spent, 
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 
    GROUP BY c.c_custkey
),
lineitem_analysis AS (
    SELECT l_orderkey, 
           SUM(l_extendedprice * (1 - l_discount)) AS total_lineitem_revenue,
           COUNT(*) AS total_line_items,
           SUM(CASE WHEN l_returnflag = 'Y' THEN 1 ELSE 0 END) AS total_returns 
    FROM lineitem
    GROUP BY l_orderkey
)
SELECT r.r_name,
       ps.total_supply_cost,
       cs.total_spent,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY cs.total_spent DESC) AS rank,
       CASE
           WHEN cs.total_orders IS NULL THEN 'Pending'
           WHEN cs.total_orders > 0 THEN 'Completed'
           ELSE 'Unknown'
       END AS order_status,
       COALESCE(la.total_lineitem_revenue, 0) AS total_revenue
FROM region_summary r
LEFT JOIN supplier_summary ss ON ss.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey = r.r_regionkey)
LEFT JOIN part_availability ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p)
LEFT JOIN customer_order_summary cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ss.s_nationkey)
LEFT JOIN lineitem_analysis la ON la.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
WHERE r.nation_count > 0
ORDER BY r.r_name, total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
