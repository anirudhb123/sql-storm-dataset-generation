WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 5
), order_summary AS (
    SELECT
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2020-01-01'
    GROUP BY c.c_custkey
), lineitem_analysis AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2020-01-01'
    GROUP BY l.l_partkey
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COALESCE(os.order_count, 0) AS order_count,
    sh.depth AS supplier_depth,
    (SELECT COUNT(DISTINCT n.n_nationkey)
     FROM nation n
     WHERE n.n_comment LIKE '%export%') AS num_nations_exporting
FROM part p
LEFT JOIN lineitem_analysis l ON p.p_partkey = l.l_partkey AND l.rnk = 1
LEFT JOIN order_summary os ON os.c_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey IN (
        SELECT sh.s_nationkey FROM supplier_hierarchy sh WHERE sh.depth = 1)
)
LEFT JOIN region r ON r.r_regionkey = (
    SELECT n.n_regionkey
    FROM nation n
    WHERE n.n_nationkey IN (
        SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT s_h.s_suppkey FROM supplier_hierarchy s_h)
    )
    LIMIT 1
)
ORDER BY total_revenue DESC, order_count DESC;
