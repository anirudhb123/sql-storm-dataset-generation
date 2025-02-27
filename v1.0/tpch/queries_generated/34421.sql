WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name = 'USA'
    )
    WHERE sh.level < 3
),
FilteredOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
      AND EXISTS (SELECT 1 
                  FROM customer c 
                  WHERE c.c_custkey = o.o_custkey AND c.c_acctbal > 1000)
    GROUP BY o.o_orderkey
),
RankedOrders AS (
    SELECT fo.o_orderkey, fo.total_revenue, 
           RANK() OVER (ORDER BY fo.total_revenue DESC) AS revenue_rank
    FROM FilteredOrders fo
)
SELECT DISTINCT p.p_name, p.p_brand, p.p_retailprice,
                (SELECT COUNT(*) FROM partsupp ps 
                 WHERE ps.ps_partkey = p.p_partkey 
                   AND ps.ps_availqty > 0) AS available_suppliers,
                sh.level AS supplier_level
FROM part p
LEFT OUTER JOIN SupplierHierarchy sh ON p.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey = sh.s_suppkey
)
JOIN RankedOrders ro ON ro.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey = p.p_partkey
)
WHERE p.p_size > 10 
  AND p.p_type LIKE 'PROMO%'
  AND sh.level IS NOT NULL
  AND (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey = ro.o_orderkey) > 5
ORDER BY p.p_brand, available_suppliers DESC;
