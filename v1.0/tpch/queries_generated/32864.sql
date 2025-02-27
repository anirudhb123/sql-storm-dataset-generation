WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_type,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue,
    AVG(l.l_discount) OVER (PARTITION BY p.p_partkey) AS avg_discount,
    COALESCE(MAX(l.l_tax), 0) AS max_tax,
    MIN(l.l_extendedprice) FILTER (WHERE l.l_returnflag = 'R') AS min_return_value,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    supplier sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN 
    nation n ON sh.s_nationkey = n.n_nationkey
WHERE 
    p.p_size BETWEEN 10 AND 50
    AND (l.l_shipmode LIKE 'AIR%' OR l.l_shipmode LIKE 'TRUCK%')
    AND sh.s_nationkey IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, p.p_type
HAVING 
    COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
