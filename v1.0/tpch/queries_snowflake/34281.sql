WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
part_supply_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
)
SELECT 
    p.p_name AS part_name,
    p.total_availqty,
    p.avg_supplycost,
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    rs.order_rank
FROM part_supply_summary p
JOIN customer_order_summary cs ON cs.total_orders > 5
LEFT JOIN ranked_orders rs ON rs.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 10000))
WHERE p.avg_supplycost < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
ORDER BY p.total_availqty DESC, cs.total_spent DESC;
