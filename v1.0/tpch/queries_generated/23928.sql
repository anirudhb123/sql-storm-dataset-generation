WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS varchar(100)) AS full_name
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CONCAT(sh.full_name, ' > ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey OR sh.s_acctbal > 1000
    WHERE LENGTH(s.s_name) > 0
),

CustomerOrderStatistics AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey
),

ProductPreferences AS (
    SELECT p.p_partkey,
           p.p_name,
           COUNT(DISTINCT CASE WHEN ps.ps_availqty > 0 THEN ps.ps_suppkey ELSE NULL END) AS supplier_count,
           AVG(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY p.p_partkey) AS avg_sale_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT 
    c.c_name AS customer_name,
    COALESCE(cos.order_count, 0) AS total_orders,
    cos.total_spent,
    sh.full_name AS supplier_hierarchy,
    pp.p_name AS popular_product,
    pp.supplier_count,
    pp.avg_sale_price
FROM customerOrderStatistics cos
FULL OUTER JOIN Customer c ON cos.c_custkey = c.c_custkey
CROSS JOIN ProductPreferences pp
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = c.c_nationkey
WHERE (cos.total_spent IS NULL OR cos.total_spent >= 1000)
  AND pp.avg_sale_price > 500
  AND EXISTS (SELECT 1 FROM lineitem l WHERE l.l_returnflag = 'R' AND l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey))
ORDER BY total_orders DESC, c.c_name ASC;
