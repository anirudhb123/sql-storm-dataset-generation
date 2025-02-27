WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
        WHERE s_nationkey IN (
            SELECT n_nationkey
            FROM nation
            WHERE n_regionkey = 1
        )
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal AND sh.level < 3
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
lineitem_stats AS (
    SELECT l_orderkey, l_partkey, l_suppkey, 
           SUM(l_extendedprice * (1 - l_discount)) AS total_sales, 
           COUNT(DISTINCT l_linenumber) AS number_of_items,
           MAX(l_shipdate) AS latest_ship_date
    FROM lineitem
    WHERE l_returnflag = 'N'
    GROUP BY l_orderkey, l_partkey, l_suppkey
)
SELECT ns.n_name, 
       COALESCE(SUM(css.total_spent), 0) AS total_customer_spent,
       COUNT(DISTINCT sh.s_suppkey) AS active_suppliers,
       COUNT(DISTINCT ls.l_orderkey) AS completed_orders,
       ROUND(AVG(ls.total_sales), 2) AS average_sales_per_order
FROM nation ns
LEFT JOIN customer_order_summary css ON css.c_custkey IN (
    SELECT c_custkey 
    FROM customer
    WHERE c_nationkey = ns.n_nationkey
    AND c_acctbal IS NOT NULL
)
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = ns.n_nationkey
LEFT JOIN lineitem_stats ls ON ls.l_suppkey IN (
    SELECT s_suppkey
    FROM supplier
    WHERE s_nationkey = ns.n_nationkey
)
GROUP BY ns.n_name
HAVING COUNT(DISTINCT css.c_custkey) > 0
ORDER BY ns.n_name ASC
FETCH FIRST 10 ROWS ONLY;
