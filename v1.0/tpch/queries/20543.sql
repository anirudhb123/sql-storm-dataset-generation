WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal AND sh.level < 2
),
PartPopularity AS (
    SELECT ps_partkey, SUM(ps_availqty) AS total_available
    FROM partsupp
    GROUP BY ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, 
           SUM(li.l_quantity) AS total_sold,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(li.l_quantity) DESC) AS rn
    FROM part p
    LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
)
SELECT DISTINCT r.r_name, 
       CASE WHEN c.order_count IS NULL THEN 'No Orders' ELSE 'Order Placed' END AS order_status,
       s.s_name AS supplier_name,
       p.p_name AS part_name,
       pp.total_available,
       LEAST(COALESCE(c.total_spent, 0), 2000.00) AS capped_spent
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN CustomerOrders c ON s.s_nationkey = c.c_custkey
LEFT JOIN TopParts p ON p.rn <= 3
LEFT JOIN PartPopularity pp ON pp.ps_partkey = p.p_partkey
WHERE s.s_acctbal IS NOT NULL
AND pp.total_available > 100
AND (s.s_comment IS NULL OR s.s_comment LIKE '%quality%')
ORDER BY r.r_name, capped_spent DESC NULLS LAST;
