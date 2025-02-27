WITH RECURSIVE ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
region_details AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count, 
           SUM(CASE WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal ELSE 0 END) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
order_stats AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(l.l_quantity) AS avg_line_quantity
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
customer_order_counts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT r.r_name,
       COALESCE(sd.total_acctbal, 0) AS total_supplier_acctbal,
       oc.order_count AS total_orders,
       SUM(os.total_revenue) AS sum_revenue,
       SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_available_quantity,
       RANK() OVER (ORDER BY SUM(os.total_revenue) DESC) AS revenue_rank
FROM region_details rd
FULL OUTER JOIN ranked_suppliers rs ON rs.rank <= 5
FULL OUTER JOIN order_stats os ON os.o_orderdate = CURRENT_DATE - INTERVAL '1 DAY'
LEFT JOIN partsupp ps ON ps.ps_supplycost < 100.00
LEFT JOIN customer_order_counts oc ON oc.order_count > 0
WHERE rd.nation_count > 0
GROUP BY r.r_name, sd.total_acctbal, oc.order_count
HAVING SUM(os.total_revenue) IS NOT NULL AND rd.total_acctbal > 1000
ORDER BY revenue_rank;
