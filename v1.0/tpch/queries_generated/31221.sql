WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineitemStats AS (
    SELECT l.l_partkey, 
           SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice) AS avg_price,
           MAX(l.l_discount) AS max_discount,
           MIN(l.l_tax) AS min_tax,
           ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_quantity) DESC) AS rank
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT p.p_partkey, p.p_name, p.p_brand, 
       COALESCE(cs.order_count, 0) AS customer_order_count,
       COALESCE(ls.total_quantity, 0) AS total_quantity,
       COALESCE(ls.avg_price, 0) AS avg_price,
       r.r_name AS region_name,
       sh.level AS supplier_level,
       CASE WHEN ls.max_discount > 0.1 THEN 'High Discount' 
            WHEN ls.min_tax < 0.05 THEN 'Low Tax' 
            ELSE 'Normal' END AS price_category
FROM part p
LEFT JOIN LineitemStats ls ON p.p_partkey = ls.l_partkey
LEFT JOIN CustomerOrders cs ON cs.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_nationkey IN (SELECT DISTINCT s_nationkey FROM SupplierHierarchy sh WHERE sh.level = 1))
JOIN region r ON r.r_regionkey = (SELECT DISTINCT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey IN (SELECT s_suppkey FROM SupplierHierarchy))
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey)
WHERE p.p_retailprice IS NOT NULL
  AND p.p_size > 10
  AND (p.p_comment LIKE '%fragile%' OR p.p_comment IS NULL)
ORDER BY total_quantity DESC, avg_price ASC
LIMIT 100;
