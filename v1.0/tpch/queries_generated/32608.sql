WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.n_nationkey, sup.s_suppkey, sup.s_name, sup.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier sup ON sh.s_suppkey = sup.s_suppkey
    JOIN nation n ON sup.s_nationkey = n.n_nationkey
    WHERE sup.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = n.n_nationkey)
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
revenue_by_region AS (
    SELECT n.n_name, SUM(oss.total_revenue) AS region_revenue
    FROM order_summary oss
    JOIN customer c ON oss.o_custkey = c.c_custkey
    JOIN supplier s ON s.s_suppkey = (SELECT ps.s_suppkey FROM partsupp ps JOIN lineitem l ON l.l_partkey = ps.ps_partkey WHERE l.l_orderkey = oss.o_orderkey LIMIT 1)
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT r.r_name, COALESCE(rb.region_revenue, 0) AS total_revenue, COUNT(sh.s_suppkey) AS supplier_count
FROM region r
LEFT JOIN revenue_by_region rb ON r.r_name = rb.n_name
LEFT JOIN supplier_hierarchy sh ON r.r_regionkey = sh.s_nationkey
GROUP BY r.r_name
ORDER BY r.r_name;
