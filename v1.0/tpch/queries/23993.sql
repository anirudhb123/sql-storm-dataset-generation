
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 
           CAST(s_name AS VARCHAR(100)) AS full_name, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, 
           CONCAT(sh.full_name, ' -> ', s.s_name) AS full_name, level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > sh.s_acctbal
)

SELECT n.n_name AS nation_name, 
       COALESCE(COUNT(DISTINCT sh.s_suppkey), 0) AS supplier_count,
       AVG(COALESCE(sh.s_acctbal, 0)) AS avg_acctbal,
       MAX(sh.s_acctbal) AS max_acctbal,
       ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY AVG(COALESCE(sh.s_acctbal, 0)) DESC) AS rank
FROM nation n
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY n.n_nationkey, n.n_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5 OR AVG(COALESCE(sh.s_acctbal, 0)) IS NULL
ORDER BY nation_name;
