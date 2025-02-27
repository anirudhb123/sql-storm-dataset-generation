WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND LENGTH(s.s_name) > 5 AND s.s_name NOT LIKE '%a%'

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal + 1000, level + 1
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE level < 10
)

SELECT r.r_name, n.n_name, COALESCE(AVG(ps.ps_supplycost), 0) AS avg_supplycost,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT s.s_suppkey) AS unique_supplier_count,
       CASE
           WHEN COUNT(DISTINCT s.s_suppkey) = 0 THEN 'No Suppliers'
           WHEN COUNT(DISTINCT s.s_suppkey) < 5 THEN 'Few Suppliers'
           ELSE 'Many Suppliers'
       END AS supplier_status
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
WHERE EXISTS (
    SELECT 1 FROM customer c
    WHERE c.c_nationkey = n.n_nationkey
    AND c.c_acctbal > (
        SELECT MAX(c2.c_acctbal) FROM customer c2
        WHERE c2.c_nationkey = n.n_nationkey
        AND c2.c_acctbal IS NOT NULL
    )
)
GROUP BY r.r_name, n.n_name
HAVING AVG(ps.ps_supplycost) > (
    SELECT AVG(ps2.ps_supplycost) * 1.1
    FROM partsupp ps2
    LEFT JOIN supplier s2 ON ps2.ps_suppkey = s2.s_suppkey
    WHERE s2.s_nationkey IS NULL
)
ORDER BY total_revenue DESC, supplier_status ASC
LIMIT 10;
