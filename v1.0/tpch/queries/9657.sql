WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name = 'FRANCE'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey = (
        SELECT ps_partkey FROM partsupp ps2
        WHERE ps2.ps_availqty > 100
        ORDER BY ps2.ps_supplycost ASC
        LIMIT 1
    )
)
SELECT s.s_suppkey, s.s_name, AVG(tag_count) AS average_parts_per_supplier
FROM SupplierHierarchy s
JOIN (
    SELECT ps.ps_suppkey, COUNT(*) AS tag_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_type LIKE '%plastic%'
    GROUP BY ps.ps_suppkey
) AS PartCount ON s.s_suppkey = PartCount.ps_suppkey
GROUP BY s.s_suppkey, s.s_name
ORDER BY average_parts_per_supplier DESC
LIMIT 10;
