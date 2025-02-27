WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           s.s_acctbal,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           s.s_acctbal,
           sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY o.o_orderkey
),
nation_sales AS (
    SELECT n.n_nationkey,
           n.n_name,
           COALESCE(SUM(os.total_sales), 0) AS total_sales
    FROM nation n
    LEFT JOIN order_summary os ON n.n_nationkey = os.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name,
       ns.n_name,
       ns.total_sales,
       sh.s_name,
       sh.s_acctbal
FROM region r
LEFT JOIN nation_sales ns ON r.r_regionkey = ns.n_nationkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = ns.n_nationkey
WHERE ns.total_sales > 1000
ORDER BY r.r_name, ns.total_sales DESC, sh.s_acctbal DESC
FETCH FIRST 10 ROWS ONLY

