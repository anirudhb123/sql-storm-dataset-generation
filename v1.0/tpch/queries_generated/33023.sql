WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.level * 1000
),
PartCountBySupplier AS (
    SELECT ps.ps_suppkey, COUNT(ps.ps_partkey) AS part_count 
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
EnhancedCustomer AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    SUM(COALESCE(total_spent, 0)) AS total_spent,
    SUM(COALESCE(part_count, 0)) AS total_parts,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN EnhancedCustomer ec ON c.c_custkey = ec.c_custkey
LEFT JOIN PartCountBySupplier pbs ON pbs.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10))
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY r.r_name
ORDER BY total_spent DESC, total_parts DESC;
