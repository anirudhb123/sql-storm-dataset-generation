WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > sh.s_acctbal
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 500
),
order_totals AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
supplier_with_parts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT ns.n_name, 
       COALESCE(sh.level, 0) AS supplier_level, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       MAX(ot.total_spent) AS max_spent,
       SUM(COALESCE(sp.total_cost, 0)) AS total_supplier_cost,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM nation ns
LEFT JOIN supplier_hierarchy sh ON ns.n_nationkey = sh.s_nationkey
LEFT JOIN customer_summary c ON c.c_nationkey = ns.n_nationkey
LEFT JOIN order_totals ot ON ot.o_custkey = c.c_custkey
LEFT JOIN supplier_with_parts sp ON sp.s_suppkey = sh.s_suppkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = sp.s_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
WHERE ns.n_nationkey IS NOT NULL
GROUP BY ns.n_name, sh.level
ORDER BY ns.n_name, supplier_level DESC;
