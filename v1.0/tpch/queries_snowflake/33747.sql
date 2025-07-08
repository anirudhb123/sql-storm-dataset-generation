WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_summary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT c.c_custkey) AS customer_count, AVG(c.c_acctbal) AS avg_acctbal
    FROM customer c
    GROUP BY c.c_nationkey
),
order_summary AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_sales, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'S') 
    GROUP BY o.o_custkey
)
SELECT
    n.n_name AS nation_name,
    COALESCE(cs.customer_count, 0) AS customer_count,
    COALESCE(cs.avg_acctbal, 0) AS avg_acct_balance,
    COALESCE(os.total_sales, 0) AS total_sales,
    COALESCE(os.order_count, 0) AS order_count,
    RANK() OVER (PARTITION BY n.n_name ORDER BY COALESCE(os.total_sales, 0) DESC) AS sales_rank
FROM nation n
LEFT JOIN customer_summary cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN order_summary os ON cs.c_nationkey = os.o_custkey
WHERE n.n_nationkey IN (SELECT n_nationkey FROM nation_hierarchy)
ORDER BY nation_name;
