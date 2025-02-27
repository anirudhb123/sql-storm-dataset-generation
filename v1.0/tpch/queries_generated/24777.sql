WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level, NULL AS parent_suppkey
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal)
                                                      FROM supplier s2
                                                      WHERE s2.s_acctbal IS NOT NULL)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1, sh.s_suppkey
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_supkey = sh.s_suppkey
)
SELECT DISTINCT
    p.p_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(li.l_extendedprice) = 0 THEN NULL
        ELSE AVG(li.l_discount) 
    END AS avg_discount,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
FROM part p
JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE li.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
  AND li.l_returnflag = 'N'
  AND (li.l_discount IS NULL OR li.l_discount < 0.10)
GROUP BY p.p_name, r.r_name
HAVING COUNT(DISTINCT s.s_nationkey) > 1
   OR (SELECT COUNT(*) FROM supplier_hierarchy sh WHERE sh.s_nationkey = n.n_nationkey AND sh.level > 1) > 0
ORDER BY revenue_rank, total_revenue DESC;
