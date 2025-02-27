WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), 
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
), 
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
part_ranking AS (
    SELECT p.p_partkey, p.p_name, RANK() OVER (ORDER BY AVG(ps.ps_supplycost) DESC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    n.n_name AS nation_name,
    sh.level AS supplier_level,
    SUM(os.total_revenue) AS total_order_revenue,
    SUM(co.total_spent) AS total_customer_spending,
    COUNT(DISTINCT pr.p_partkey) AS ranked_parts
FROM nation n
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN order_summary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
LEFT JOIN customer_orders co ON co.c_custkey = c.c_custkey
LEFT JOIN part_ranking pr ON pr.cost_rank < 10
WHERE n.n_regionkey IS NOT NULL
GROUP BY n.n_name, sh.level
HAVING SUM(co.total_spent) > 1000
ORDER BY total_order_revenue DESC, ranked_parts ASC;
