WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
),
nation_details AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
supplier_totals AS (
    SELECT sh.s_nationkey, COUNT(DISTINCT sh.s_suppkey) AS supplier_count, SUM(sh.s_acctbal) AS total_acctbal
    FROM supplier_hierarchy sh
    GROUP BY sh.s_nationkey
)
SELECT nd.n_name, nd.region_name, st.supplier_count, st.total_acctbal, COALESCE(os.total_sales, 0) AS total_sales
FROM nation_details nd
LEFT JOIN supplier_totals st ON nd.n_nationkey = st.s_nationkey
LEFT JOIN order_summary os ON os.o_custkey = (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = nd.n_nationkey
    LIMIT 1
)
ORDER BY nd.n_name, st.supplier_count DESC, total_sales DESC;
