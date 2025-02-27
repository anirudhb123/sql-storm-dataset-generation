WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           (SELECT COUNT(DISTINCT(ps_partkey)) 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = s.s_suppkey) AS num_parts,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           (SELECT COUNT(DISTINCT(ps_partkey)) 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = s.s_suppkey) AS num_parts,
           sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
), total_sales AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus NOT IN ('O', 'F') 
    GROUP BY o.o_custkey
), customer_rating AS (
    SELECT c.c_custkey, c.c_name, 
           CASE 
               WHEN c.c_acctbal > 5000 THEN 'Gold'
               WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Silver'
               ELSE 'Bronze'
           END AS rating
    FROM customer c
), enriched_sales AS (
    SELECT tr.o_custkey, tr.total_spent, cr.rating,
           ROW_NUMBER() OVER (PARTITION BY cr.rating ORDER BY tr.total_spent DESC) AS rank
    FROM total_sales tr
    JOIN customer_rating cr ON tr.o_custkey = cr.c_custkey
)
SELECT sh.s_name, sh.num_parts, es.total_spent, es.rating
FROM supplier_hierarchy sh
LEFT JOIN enriched_sales es ON sh.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
WHERE (es.rating IS NOT NULL OR sh.num_parts > 2) 
AND EXISTS (
    SELECT 1 FROM partsupp ps
    WHERE ps.ps_suppkey = sh.s_suppkey AND ps.ps_availqty IS NOT NULL
)
ORDER BY sh.level, es.total_spent DESC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM supplier) / 2;
