
WITH RECURSIVE Supplier_Hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, 
           sh.level + 1
    FROM supplier s
    JOIN Supplier_Hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(s.s_acctbal) AS total_acctbal,
    AVG(CASE WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal ELSE 0 END) AS avg_acctbal,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS popular_parts,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(s.s_acctbal) DESC) AS row_num
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE s.s_acctbal > (
    SELECT AVG(s2.s_acctbal) 
    FROM supplier s2 
    WHERE s2.s_acctbal IS NOT NULL
)
GROUP BY n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY total_acctbal DESC, nation_name;
