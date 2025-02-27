WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_size, p_retailprice,
           COALESCE(NULLIF(p_comment, ''), 'No comment available') AS p_comment,
           1 AS level
    FROM part
    WHERE p_size > 20

    UNION ALL

    SELECT p.p_partkey, CONCAT(ph.p_name, ' -> ', p.p_name), p.p_brand, p.p_size, p.p_retailprice,
           COALESCE(NULLIF(p.p_comment, ''), 'No comment available') AS p_comment,
           ph.level + 1
    FROM part p
    JOIN part_hierarchy ph ON p.p_size = ph.p_size + 10
)

SELECT r.r_name, n.n_name, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns,
       ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY total_revenue DESC) AS revenue_rank
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_partkey = ps.ps_partkey
WHERE l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
  AND ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_availqty > 100)
GROUP BY r.r_name, n.n_name, s.s_name
HAVING total_revenue IS NOT NULL AND total_returns IS NOT NULL
ORDER BY revenue_rank
FETCH FIRST 10 ROWS ONLY;

SELECT 
    p1.p_name AS expensive_part,
    COUNT(*) AS supplier_count
FROM part p1
JOIN partsupp ps1 ON p1.p_partkey = ps1.ps_partkey
WHERE ps1.ps_supplycost = (SELECT MAX(ps_supplycost) FROM partsupp)
GROUP BY p1.p_name
HAVING COUNT(DISTINCT ps1.ps_suppkey) > 1
EXCEPT
SELECT 
    p2.p_name AS average_part,
    COUNT(*) AS supplier_count
FROM part p2
JOIN partsupp ps2 ON p2.p_partkey = ps2.ps_partkey
WHERE ps2.ps_supplycost = (SELECT AVG(ps_supplycost) FROM partsupp)
GROUP BY p2.p_name
HAVING COUNT(DISTINCT ps2.ps_suppkey) = 1;
