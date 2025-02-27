WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
nation_info AS (
    SELECT n.n_nationkey, n.n_name, n.n_comment, 
           (SELECT COUNT(DISTINCT s.s_suppkey) 
            FROM supplier s 
            WHERE s.s_nationkey = n.n_nationkey) AS supplier_count,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY n.n_name) AS row_num
    FROM nation n
)

SELECT DISTINCT p.p_partkey, 
                p.p_name, 
                p.p_retailprice, 
                n.n_name AS nation_name, 
                sh.s_name AS supplier_name,
                CASE 
                    WHEN p.p_size > 20 THEN 'Large'
                    WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
                    ELSE 'Small'
                END AS size_category,
                COALESCE(sh.s_nationkey, -1) AS supplier_nationkey,
                SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY p.p_partkey) AS total_revenue
FROM part p
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = ps.ps_suppkey
JOIN nation_info n ON n.n_nationkey = sh.s_nationkey
WHERE p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2) 
  AND (n.supplier_count > 10 OR n.n_comment IS NULL)
  AND (sh.level IS NULL OR sh.level <= 3)
ORDER BY p.p_partkey, sh.level DESC
LIMIT 100
OFFSET (SELECT COUNT(DISTINCT c.c_custkey) 
        FROM customer c 
        WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment NOT LIKE 'AUTOMOBILE')
;
