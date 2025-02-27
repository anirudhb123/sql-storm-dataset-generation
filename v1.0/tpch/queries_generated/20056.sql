WITH RECURSIVE national_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal + COALESCE(NULLIF(s.s_acctbal * 0.1, 0), 0) AS adjusted_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ns.adjusted_acctbal + COALESCE(NULLIF(s.s_acctbal * 0.1, 0), 0)
    FROM supplier s
    JOIN national_suppliers ns ON s.s_nationkey = ns.s_nationkey
    WHERE ns.adjusted_acctbal < 1000
),
order_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count, MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
part_revenue AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
    GROUP BY p.p_partkey
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, r.revenue, RANK() OVER (ORDER BY r.revenue DESC) AS revenue_rank
    FROM part_revenue r
    JOIN part p ON r.p_partkey = p.p_partkey
),
final_results AS (
    SELECT ns.s_name, ns.adjusted_acctbal, os.total_spent, rp.p_name, rp.revenue_rank
    FROM national_suppliers ns
    LEFT JOIN order_summary os ON os.c_custkey = ns.s_nationkey
    FULL OUTER JOIN ranked_parts rp ON rp.revenue_rank = (SELECT COUNT(*) FROM ranked_parts rp2 WHERE rp2.revenue > rp.revenue)
)
SELECT *
FROM final_results
WHERE (adjusted_acctbal IS NOT NULL AND total_spent IS NOT NULL)
OR (adjusted_acctbal >= 500 AND revenue_rank < 10);
