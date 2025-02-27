WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_suppkey = (sh.s_nationkey + 1) -- assuming a relationship
    WHERE sh.level < 5
),
part_sales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, ps.total_sales, 
           RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
    FROM part p
    JOIN part_sales ps ON p.p_partkey = ps.p_partkey
)
SELECT r.r_name, n.n_name, sp.s_name, rp.p_name, rp.total_sales
FROM ranked_parts rp
LEFT JOIN supplier_hierarchy sh ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sh.s_suppkey)
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rp.total_sales > 10000
  AND r.r_name IS NOT NULL
  AND n.n_name NOT IN (SELECT DISTINCT n1.n_name FROM nation n1 WHERE n1.n_nationkey IS NULL)
ORDER BY r.r_name, rp.sales_rank
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
