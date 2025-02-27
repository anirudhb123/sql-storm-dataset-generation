WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
lineitem_analysis AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY l.l_orderkey, l.l_partkey
)
SELECT
    CASE
        WHEN COALESCE(c.order_count, 0) = 0 THEN 'No Orders'
        ELSE 'Orders: ' || c.order_count || ' '
    END AS order_info,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    COALESCE((SELECT COUNT(*) FROM supplier_hierarchy sh WHERE sh.s_nationkey = c.c_nationkey), 0) AS suppliers_in_same_nation,
    SUM(COALESCE(la.revenue, 0)) AS total_revenue,
    RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(COALESCE(la.revenue, 0)) DESC) AS revenue_rank
FROM customer_orders c
LEFT JOIN lineitem_analysis la ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = la.l_orderkey LIMIT 1)
GROUP BY c.c_custkey, c.c_name, c.c_acctbal
HAVING SUM(COALESCE(la.revenue, 0)) > (SELECT AVG(total_spent) FROM customer_orders)
OR c.c_acctbal IS NULL
ORDER BY revenue_rank
LIMIT 10;
