WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 30000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, (sh.s_acctbal + s.s_acctbal) AS total_acctbal, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice END) AS total_open_orders,
    MAX(l.l_discount) AS max_discount,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_availability,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COUNT(DISTINCT c.c_custkey) DESC) AS rank
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%East%')
AND (sh.total_acctbal > 50000 OR sh.suppkey IS NULL)
GROUP BY n.n_nationkey, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY customer_count DESC
LIMIT 50;
