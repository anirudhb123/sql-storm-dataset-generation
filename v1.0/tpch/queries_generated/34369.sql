WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey, l.l_partkey
)

SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       COALESCE(SUM(co.total_spent), 0) AS total_revenue,
       ARRAY_AGG(DISTINCT s.s_name) AS suppliers,
       COUNT(ld.l_orderkey) FILTER (WHERE ld.rn = 1) AS orders_with_highest_value
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN CustomerOrders co ON co.order_count > 0
LEFT JOIN LineItemDetails ld ON ld.l_orderkey IN (SELECT o.o_orderkey FROM orders o
                                                  WHERE o.o_orderstatus IN ('O', 'F'))
WHERE s.s_nationkey IN (SELECT n_nationkey FROM SupplierHierarchy)
GROUP BY r.r_name
ORDER BY total_revenue DESC
LIMIT 10;
