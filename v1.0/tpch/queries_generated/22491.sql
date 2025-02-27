WITH RECURSIVE region_stats AS (
    SELECT r_regionkey, r_name, COUNT(n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r_regionkey, r_name
),
supplier_stats AS (
    SELECT s_nationkey, AVG(s_acctbal) AS avg_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
order_summary AS (
    SELECT o_custkey, SUM(o_totalprice) AS total_spent,
           COUNT(DISTINCT o_orderkey) AS order_count,
           RANK() OVER (PARTITION BY o_custkey ORDER BY SUM(o_totalprice) DESC) AS rank_spent
    FROM orders
    GROUP BY o_custkey
),
lineitem_details AS (
    SELECT l_orderkey, SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) AS returned_qty,
           SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
           COUNT(*) AS line_count
    FROM lineitem
    GROUP BY l_orderkey
)
SELECT r.r_name, rs.nation_count, ss.avg_acctbal, os.total_spent, ld.total_revenue,
       CASE WHEN ld.returned_qty > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_status,
       CASE 
           WHEN os.order_count IS NULL THEN 'No Orders'
           WHEN os.order_count > 10 THEN 'Frequent Buyer'
           ELSE 'Occasional Buyer'
       END AS buyer_type,
       COALESCE(ld.line_count, 0) AS line_item_count,
       CASE 
           WHEN COALESCE(ld.line_count, 0) > (SELECT AVG(line_count) FROM lineitem_details) 
           THEN 'Above Average Line Items' 
           ELSE 'Below Average Line Items' 
       END AS lineitem_comparison
FROM region_stats rs
FULL OUTER JOIN supplier_stats ss ON ss.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rs.r_regionkey LIMIT 1)
LEFT JOIN order_summary os ON os.o_custkey = (SELECT RANDOM() FROM customer ORDER BY RANDOM() LIMIT 1)
LEFT JOIN lineitem_details ld ON ld.l_orderkey = os.o_custkey
WHERE (rs.nation_count IS NOT NULL OR ss.avg_acctbal IS NOT NULL)
  AND (ss.avg_acctbal IS NOT NULL AND ss.avg_acctbal < (SELECT AVG(s_acctbal) FROM supplier) OR ss.avg_acctbal IS NULL)
  AND (r.r_name ILIKE '%East%' OR r.r_name ILIKE '%West%')
ORDER BY r.r_name, os.total_spent DESC
LIMIT 50 OFFSET 5;
