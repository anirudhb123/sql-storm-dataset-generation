WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartCount AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    AVG(CASE WHEN co.order_count IS NULL THEN 0 ELSE co.order_count END) AS avg_order_per_customer,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY total_revenue DESC) AS rank,
    COUNT(DISTINCT sh.s_suppkey) AS unique_suppliers
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey 
LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerOrders co ON co.order_count > 0
WHERE p.p_size BETWEEN 10 AND 50
  AND (p.p_comment IS NOT NULL OR p.p_brand = 'Brand#123')
  AND (LENGTH(p.p_name) % 2 = 0 OR p.p_retailprice IS NOT NULL)
GROUP BY p.p_name, r.r_name
HAVING total_revenue > (SELECT AVG(total_revenue) FROM 
                          (SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
                           FROM part p
                           JOIN lineitem l ON p.p_partkey = l.l_partkey
                           GROUP BY p.p_partkey) AS subquery)
ORDER BY total_revenue DESC NULLS LAST;
