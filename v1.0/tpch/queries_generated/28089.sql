WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT r.r_name, COUNT(DISTINCT p.p_partkey) AS part_count, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       STRING_AGG(DISTINCT CONCAT(s.s_name, ' (Level ', sh.level, ')'), ', ') AS supplier_names
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_comment LIKE '%green%'
  AND l.l_shipdate >= DATE '2023-01-01'
  AND l.l_shipdate < DATE '2024-01-01'
GROUP BY r.r_name
ORDER BY total_revenue DESC;
