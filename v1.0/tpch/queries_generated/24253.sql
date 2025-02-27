WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT 
    DISTINCT p.p_name,
    n.n_name AS nation,
    COALESCE(MAX(ps.ps_availqty) OVER (PARTITION BY p.p_partkey), 0) AS max_avail_qty,
    CASE 
        WHEN p.p_size IS NULL THEN 'N/A'
        WHEN p.p_size < 5 THEN 'Small'
        WHEN p.p_size BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Large'
    END AS part_size_category,
    ARRAY_AGG(DISTINCT sh.s_name) FILTER (WHERE sh.Level > 0) AS all_suppliers
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey 
                                   FROM orders o 
                                   WHERE o.o_orderkey = (SELECT l.l_orderkey 
                                                          FROM lineitem l 
                                                          WHERE l.l_partkey = p.p_partkey 
                                                          AND l.l_discount < 0.05
                                                          LIMIT 1))
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
WHERE 
    n.n_nationkey IS NOT NULL AND 
    (p.p_comment LIKE '%premium%' OR p.p_mfgr NOT IN ('MFGR1', 'MFGR2'))
GROUP BY 
    p.p_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2 AND
    SUM(ps.ps_supplycost) IS NOT NULL
ORDER BY 
    max_avail_qty DESC,
    part_size_category ASC;
