WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
total_price AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount BETWEEN 0 AND 0.1
    GROUP BY o.o_orderkey
),
avg_price AS (
    SELECT AVG(total) AS avg_total
    FROM total_price
),
final_result AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           MAX(ps.ps_supplycost) AS max_cost, MIN(ps.ps_supplycost) AS min_cost,
           (MAX(ps.ps_supplycost) - MIN(ps.ps_supplycost)) AS cost_diff,
           CASE WHEN AVG(total) > (SELECT avg_total FROM avg_price) THEN 'Above Average' ELSE 'Below Average' END AS price_comparison
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN total_price tp ON tp.o_orderkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 1
    ORDER BY price_comparison DESC, p.p_partkey
)
SELECT fh.*, r.r_name
FROM final_result fh
LEFT JOIN nation n ON fh.supplier_count = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name IS NOT NULL
AND fh.cost_diff IS NOT NULL
AND (fh.supplier_count IN (SELECT DISTINCT s_nationkey FROM supplier WHERE s_acctbal IS NULL)
         OR fh.max_cost > fh.min_cost)
OR fh.p_partkey IN (SELECT p_partkey FROM part WHERE p_retailprice > 100)
ORDER BY fh.p_partkey DESC;
