WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS depth
    FROM nation n
    WHERE n.n_name LIKE 'A%'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey,
           COUNT(l.l_orderkey) AS total_lines,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
filtered_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment,
           CASE WHEN c.c_acctbal IS NULL THEN 0 ELSE c.c_acctbal END AS acct_balance
    FROM customer c
    WHERE c.c_mktsegment IN (SELECT DISTINCT c_mktsegment FROM customer WHERE c_acctbal < 1000)
),
final_output AS (
    SELECT ni.n_name AS nation_name, 
           COUNT(DISTINCT sf.s_suppkey) AS supplier_count,
           SUM(os.total_revenue) AS total_revenue,
           AVG(cs.acct_balance) AS average_account_balance
    FROM nation_hierarchy ni
    LEFT JOIN supplier_info sf ON ni.n_nationkey = sf.s_nationkey
    LEFT JOIN order_summary os ON sf.s_suppkey = os.o_custkey
    LEFT JOIN filtered_customers cs ON os.o_custkey = cs.c_custkey
    GROUP BY ni.n_name
)
SELECT *
FROM final_output
WHERE average_account_balance > (SELECT AVG(acct_balance) FROM filtered_customers) 
AND supplier_count > (
    SELECT COUNT(*) FROM supplier_info WHERE total_supplycost < 10000
)
ORDER BY total_revenue DESC, nation_name;
