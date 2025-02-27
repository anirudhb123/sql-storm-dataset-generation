WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_returns,
       AVG(l.l_extendedprice) OVER (PARTITION BY r.r_name) AS avg_extended_price,
       STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE p.p_retailprice IS NOT NULL
AND (l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' OR l.l_discount IS NULL)
GROUP BY r.r_name
HAVING total_returns > COALESCE(MAX(l.l_extendedprice), 0) * 0.5
ORDER BY total_customers DESC;
