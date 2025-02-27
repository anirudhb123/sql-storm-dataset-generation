WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal = (SELECT MAX(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey AND sh.level < 3
),
PartPriceOptimization AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COUNT(ps.ps_availqty) AS available_suppliers,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
Top3Parts AS (
    SELECT ppo.p_partkey, ppo.p_name, ppo.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY ppo.available_suppliers ORDER BY ppo.total_sales DESC) AS rank
    FROM PartPriceOptimization ppo
)
SELECT 
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    tp.p_name AS top_part_name,
    tp.p_retailprice,
    ps.ps_availqty,
    COALESCE(MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END), 0) AS total_returned,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM nation n
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN Top3Parts tp ON ps.ps_partkey = tp.p_partkey
LEFT JOIN orders o ON o.o_custkey = s.s_suppkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE tp.rank <= 3 AND (n.n_name LIKE '%land%' OR (s.s_acctbal IS NOT NULL AND s.s_acctbal > 500))
GROUP BY n.n_name, s.s_name, tp.p_name, tp.p_retailprice, ps.ps_availqty
HAVING SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * l.l_discount END) IS NULL 
   OR COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY total_orders DESC, top_part_name ASC;
