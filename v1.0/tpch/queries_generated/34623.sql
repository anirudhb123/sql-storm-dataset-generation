WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 0
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(s.s_acctbal) IS NOT NULL
),
part_sales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2021-01-01'
    GROUP BY p.p_partkey
),
ranked_parts AS (
    SELECT p.p_name, ps.total_revenue,
           RANK() OVER (ORDER BY ps.total_revenue DESC) AS revenue_rank
    FROM part_sales ps
    JOIN part p ON ps.p_partkey = p.p_partkey
)
SELECT n.n_name, cs.c_name, r.p_name, r.total_revenue,
       COALESCE(supplier_h.level, 0) AS supplier_level
FROM nation_summary n
JOIN customer_orders cs ON n.n_nationkey = cs.c_custkey
JOIN ranked_parts r ON r.total_revenue > 10000
LEFT JOIN supplier_hierarchy supplier_h ON n.n_nationkey = supplier_h.s_nationkey
WHERE r.revenue_rank <= 10 AND cs.total_orders > 5
ORDER BY n.n_name, cs.c_name, r.total_revenue DESC;
