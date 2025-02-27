WITH RECURSIVE supply_chain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN supply_chain sc ON ps.ps_partkey = sc.ps_partkey
    WHERE ps.ps_availqty > sc.ps_availqty
),

order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),

nation_details AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),

final_summary AS (
    SELECT p.p_name, COUNT(DISTINCT sc.s_suppkey) AS supplier_count,
           SUM(os.total_price) AS total_order_value,
           nd.total_balance AS nation_balance
    FROM part p
    LEFT JOIN supply_chain sc ON p.p_partkey = sc.ps_partkey
    LEFT JOIN order_summary os ON os.o_orderkey = sc.ps_partkey
    LEFT JOIN nation_details nd ON nd.n_nationkey = (SELECT n.n_nationkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = sc.s_suppkey LIMIT 1)
    GROUP BY p.p_name, nd.total_balance
)

SELECT f.p_name,
       f.supplier_count,
       f.total_order_value,
       f.nation_balance,
       CASE 
           WHEN f.total_order_value IS NULL THEN 'No Orders'
           WHEN f.total_order_value < 1000 THEN 'Low Sales'
           ELSE 'High Sales'
       END AS sales_category
FROM final_summary f
WHERE f.nation_balance IS NOT NULL
ORDER BY f.supplier_count DESC, f.total_order_value DESC;
