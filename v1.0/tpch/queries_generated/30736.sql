WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    AVG(o.o_totalprice) AS avg_order_price,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned,
    COUNT(DISTINCT p.p_partkey) AS num_parts,
    SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_quantity,
    MAX(l.l_discount) OVER (PARTITION BY r.r_name) AS max_discount_by_region
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND ps.ps_suppkey IN (SELECT s_suppkey FROM SupplierHierarchy WHERE level = 1)
LEFT JOIN part p ON p.p_partkey = l.l_partkey
WHERE r.r_comment IS NOT NULL
AND r.r_name LIKE 'A%'
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY num_customers DESC, avg_order_price DESC;
