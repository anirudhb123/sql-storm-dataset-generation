
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
part_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
customer_spent AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
critical_customers AS (
    SELECT c.c_custkey, c.c_name, cs.total_spent
    FROM customer c
    JOIN customer_spent cs ON c.c_custkey = cs.c_custkey
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM customer_spent)
),
final_report AS (
    SELECT p.p_partkey, p.p_name, ps.total_available, ps.avg_supply_cost,
           sh.s_name AS supplier_name, cc.c_name AS customer_name
    FROM part p
    JOIN part_summary ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = sh.s_nationkey
    LEFT JOIN ranked_orders ro ON ro.o_custkey = ro.o_custkey
    LEFT JOIN critical_customers cc ON cc.c_custkey = ro.o_custkey
    WHERE ps.total_available > 0 AND ps.avg_supply_cost < 500.00
)
SELECT r.p_partkey, r.p_name, r.total_available, r.avg_supply_cost, 
       COALESCE(r.supplier_name, 'No Supplier') AS supplier_name,
       COALESCE(r.customer_name, 'No Customer') AS customer_name
FROM final_report r
ORDER BY r.total_available DESC, r.avg_supply_cost ASC;
