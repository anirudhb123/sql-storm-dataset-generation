WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
extended_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rank_order
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice
),
max_revenue AS (
    SELECT o.o_custkey, MAX(total_revenue) AS max_revenue_value
    FROM extended_orders o
    GROUP BY o.o_custkey
),
supplier_region AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
ranked_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    s.s_name AS supplier_name,
    sr.region_name,
    rc.c_name AS customer_name,
    rc.c_acctbal,
    mr.max_revenue_value,
    sh.level AS supplier_level
FROM supplier_hierarchy sh
JOIN supplier_region sr ON sh.s_suppkey = sr.s_suppkey
JOIN ranked_customers rc ON rc.nation_name = sr.nation_name
JOIN max_revenue mr ON rc.c_custkey = mr.o_custkey
WHERE rc.rank_acctbal <= 5 AND mr.max_revenue_value IS NOT NULL
ORDER BY sr.region_name, supplier_level, rc.c_acctbal DESC;
