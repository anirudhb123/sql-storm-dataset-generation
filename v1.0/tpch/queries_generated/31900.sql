WITH RECURSIVE supplier_hierarchy(s_suppkey, s_name, level) AS (
    SELECT s.s_suppkey, s.s_name, 1
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    UNION ALL
    SELECT ss.s_suppkey, ss.s_name, sh.level + 1
    FROM supplier ss
    JOIN partsupp ps ON ss.s_suppkey = ps.ps_suppkey
    JOIN supplier_hierarchy sh ON ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_size > (
            SELECT AVG(p2.p_size) FROM part p2 WHERE p2.p_mfgr = 'Manufacturer1'
        )
    )
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > '2023-01-01'
    GROUP BY o.o_orderkey
),
nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name IS NOT NULL
),
ranked_orders AS (
    SELECT o.o_orderkey, RANK() OVER (PARTITION BY n.n_name ORDER BY os.total_price DESC) AS order_rank
    FROM order_summary os
    JOIN customer c ON os.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT nh.s_name, COUNT(DISTINCT so.o_orderkey) AS total_orders, SUM(os.total_price) AS total_revenue
FROM supplier_hierarchy nh
LEFT JOIN ranked_orders so ON so.order_rank <= 5
JOIN order_summary os ON so.o_orderkey = os.o_orderkey
WHERE nh.level <= 3
GROUP BY nh.s_name
HAVING SUM(os.total_price) IS NOT NULL AND COUNT(DISTINCT so.o_orderkey) > 0
ORDER BY total_revenue DESC;
