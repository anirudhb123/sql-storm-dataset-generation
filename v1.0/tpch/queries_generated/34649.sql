WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.nationkey = sh.nationkey
    WHERE sh.level < 5
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, ps.ps_comment
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > (
        SELECT AVG(ps_availqty)
        FROM partsupp
        WHERE ps_supplycost < 50
    )
),
order_details AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, o.o_orderpriority
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderpriority
),
customer_summary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spend
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
final_summary AS (
    SELECT n.n_nationkey, n.n_name, s.s_name, COALESCE(cs.total_spend, 0) AS customer_spend, SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_costs
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer_summary cs ON cs.c_custkey = s.s_suppkey
    LEFT JOIN part_supplier ps ON ps.ps_supplycost > 20
    GROUP BY n.n_nationkey, n.n_name, s.s_name, cs.total_spend
),
ranked_summary AS (
    SELECT fs.*, RANK() OVER (PARTITION BY fs.n_nationkey ORDER BY fs.customer_spend DESC) AS spend_rank
    FROM final_summary fs
)
SELECT r.r_name, rs.s_name, rs.customer_spend, rs.supplier_costs
FROM ranked_summary rs
JOIN region r ON rs.n_nationkey = r.r_regionkey
WHERE rs.supplier_costs IS NOT NULL
ORDER BY r.r_name, rs.customer_spend DESC;
