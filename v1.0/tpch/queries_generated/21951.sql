WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           s.s_acctbal, 
           CAST(0 AS INTEGER) AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           s.s_acctbal, 
           sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE s.s_acctbal BETWEEN sh.s_acctbal AND sh.s_acctbal + 5000
),
order_summary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           MAX(l.l_tax) AS max_tax,
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY o.o_orderkey
),
nation_sales AS (
    SELECT n.n_name, 
           SUM(os.total_sales) AS total_sales_gain,
           COUNT(os.o_orderkey) AS order_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN order_summary os ON o.o_orderkey = os.o_orderkey
    WHERE n.n_name IS NOT NULL
    GROUP BY n.n_name
)
SELECT rh.s_name, 
       r.r_name,
       ns.total_sales_gain,
       GREATEST(ns.order_count, 1) AS active_orders,
       CASE WHEN ns.total_sales_gain IS NULL THEN 0 ELSE ns.total_sales_gain END AS adjusted_sales
FROM supplier_hierarchy rh
FULL OUTER JOIN region r ON r.r_regionkey = rh.s_nationkey
LEFT JOIN nation_sales ns ON ns.total_sales_gain > 100000
WHERE rh.level <= 2
ORDER BY adjusted_sales DESC
LIMIT 10;
