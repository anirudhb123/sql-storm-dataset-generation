WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 3
),
MaxSupplierCost AS (
    SELECT ps.ps_partkey, MAX(ps.ps_supplycost) AS max_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT p.*, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
)
SELECT r.r_name AS region_name, 
       n.n_name AS nation_name,
       p.p_name AS part_name,
       p.p_retailprice AS retail_price,
       p.p_size AS size,
       COALESCE(l.total_sales, 0) AS total_sales,
       CASE 
           WHEN p.p_size > 50 THEN 'Large'
           WHEN p.p_size BETWEEN 20 AND 50 THEN 'Medium'
           ELSE 'Small'
       END AS size_category
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN MaxSupplierCost msc ON true
LEFT JOIN PartDetails p ON p.p_partkey = msc.ps_partkey
LEFT JOIN (
    SELECT l.l_partkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales 
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY l.l_partkey
) l ON l.l_partkey = p.p_partkey
WHERE sh.depth IS NOT NULL
  AND p.p_retailprice >= (SELECT AVG(p2.p_retailprice) FROM part p2)
  AND n.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_mktsegment = 'BUILDING')
ORDER BY region_name, nation_name, retail_price DESC, size_category;