WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_comment IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_size BETWEEN 10 AND 20
        )
        ORDER BY ps.ps_supplycost DESC
        LIMIT 1
    )
)
SELECT 
    sub.n_name,
    MAX(l.l_extendedprice) AS max_price,
    SUM(CASE 
        WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount)
        ELSE l.l_extendedprice 
    END) AS discounted_total,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS returns_count,
    STRING_AGG(DISTINCT ph.p_name, ', ') FILTER (WHERE l.l_tax IS NOT NULL) AS part_names
FROM lineitem l
LEFT OUTER JOIN orders o ON l.l_orderkey = o.o_orderkey 
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
INNER JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN (
    SELECT * FROM SupplierHierarchy
    WHERE level = (SELECT MAX(level) FROM SupplierHierarchy)
) sh ON s.s_suppkey = sh.s_suppkey
WHERE l.l_shipdate >= '2023-01-01'
AND (r.r_name LIKE '%North%' OR r.r_name IS NULL)
GROUP BY sub.n_name
ORDER BY max_price DESC 
FETCH FIRST 10 ROWS ONLY;
