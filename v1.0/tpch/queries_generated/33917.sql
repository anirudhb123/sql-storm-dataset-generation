WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(o.o_totalprice) AS total_revenue,
       AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value,
       MAX(l.l_shipdate) AS last_ship_date
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE l.l_shipdate > DATE '2023-01-01'
  AND (n.r_comment IS NULL OR n.r_comment LIKE '%supplier%')
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;
