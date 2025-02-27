WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) * (1 + sh.level * 0.1)
),

part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, s.s_name, r.r_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
),

customer_order_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),

final_selection AS (
    SELECT ps.p_name AS part_name, ps.s_name AS supplier_name, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank,
           coh.total_spent
    FROM part_supplier ps
    JOIN customer_order_summary coh ON ps.s_name = coh.c_custkey
    WHERE ps.ps_availqty > 0 AND ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)

SELECT f.part_name, f.supplier_name, f.ps_supplycost, 
       (SELECT COUNT(*) FROM supplier_hierarchy sh WHERE sh.level <= 2) AS suppliers_in_hierarchy,
       f.total_spent
FROM final_selection f
WHERE f.rank = 1 AND f.total_spent IS NOT NULL
ORDER BY f.total_spent DESC
LIMIT 10;
