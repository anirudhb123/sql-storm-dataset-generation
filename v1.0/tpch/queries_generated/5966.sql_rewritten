WITH top_nations AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY total_acctbal DESC
    LIMIT 5
),
recent_orders AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_custkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, coalesce(ro.total_revenue, 0) AS total_revenue, 
           CASE WHEN ro.total_revenue > 10000 THEN 'High Value' 
                WHEN ro.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value' 
                ELSE 'Low Value' END AS customer_value
    FROM customer c
    LEFT JOIN recent_orders ro ON c.c_custkey = ro.o_custkey
),
parts_statistics AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, ps.avg_supplycost, ps.supplier_count,
           RANK() OVER (ORDER BY ps.avg_supplycost DESC) as cost_rank
    FROM part p
    JOIN parts_statistics ps ON p.p_partkey = ps.p_partkey
)
SELECT cn.n_name, cs.c_name, cs.total_revenue, cs.customer_value, rp.p_name, rp.avg_supplycost
FROM top_nations cn
JOIN customer_summary cs ON cn.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE cs.c_custkey = c.c_custkey)
JOIN ranked_parts rp ON rp.cost_rank <= 10
WHERE cs.total_revenue > 5000
ORDER BY cs.total_revenue DESC, rp.avg_supplycost ASC;