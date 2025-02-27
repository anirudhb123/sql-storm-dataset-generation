WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= (SELECT AVG(s_acctbal) FROM supplier)
),
part_stats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           RANK() OVER (ORDER BY COALESCE(SUM(o.o_totalprice), 0) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING order_count > 0
)
SELECT s.s_name, r.r_name, 
       ps.total_available, ps.avg_cost, 
       cs.total_spent, cs.order_count,
       CASE 
           WHEN cs.spending_rank < 5 THEN 'Top Customer'
           ELSE 'Regular Customer'
       END AS customer_type
FROM supplier_hierarchy s
LEFT JOIN region r ON s.s_nationkey = r.r_regionkey
JOIN part_stats ps ON s.s_suppkey = ps.p_partkey
JOIN customer_summary cs ON cs.total_spent > ps.avg_cost
ORDER BY ps.total_available DESC, cs.total_spent DESC;
