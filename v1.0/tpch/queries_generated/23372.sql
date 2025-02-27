WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), 
part_category AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           CASE 
               WHEN p.p_size < 20 THEN 'Small'
               WHEN p.p_size BETWEEN 20 AND 50 THEN 'Medium'
               ELSE 'Large'
           END AS size_category
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_size
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ph.s_name AS supplier_name,
    pc.size_category,
    co.total_spent,
    COALESCE(co.total_spent, 0) * (CASE WHEN co.spending_rank <= 10 THEN 0.1 ELSE 0.05 END) AS discount_adjusted
FROM supplier_hierarchy ph
FULL OUTER JOIN part_category pc ON ph.level = pc.supplier_count
LEFT JOIN customer_orders co ON ph.s_nationkey = co.c_custkey
WHERE (ph.s_nationkey IS NOT NULL OR pc.size_category IS NOT NULL)
  AND (co.total_spent IS NULL OR co.total_spent > 100)
ORDER BY discount_adjusted DESC, ph.s_name NULLS LAST;
