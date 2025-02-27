WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, 0 AS level
    FROM supplier s
    INNER JOIN nation n ON s.n_nationkey = n.n_nationkey
    WHERE n.n_name = 'USA'
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON p.p_partkey = ps.ps_partkey
    WHERE sh.level < 3
)
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
    AVG(s.s_acctbal) AS avg_acctbal,
    SUM(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS total_acctbal,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY AVG(s.s_acctbal) DESC) AS supplier_rank,
    COALESCE(STRING_AGG(DISTINCT s.s_name, ', '), 'No Suppliers') AS supplier_names
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_size > 10 AND (p.p_retailprice IS NOT NULL OR s.s_acctbal > 100)
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY avg_acctbal DESC
FETCH FIRST 10 ROWS ONLY;
