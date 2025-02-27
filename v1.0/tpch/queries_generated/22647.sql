WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_suppkey, 
           CASE 
               WHEN ps.ps_availqty > 500 THEN 'High'
               WHEN ps.ps_availqty BETWEEN 200 AND 500 THEN 'Medium'
               ELSE 'Low' 
           END AS availability
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT c.c_name, COALESCE(co.order_count, 0) AS order_count, COALESCE(co.total_spent, 0) AS total_spent,
       p.p_name, psi.availability, sh.level
FROM CustomerOrders co
FULL OUTER JOIN PartSupplierInfo psi ON co.c_custkey = psi.ps_suppkey
JOIN SupplierHierarchy sh ON psi.s_suppkey = sh.s_suppkey
WHERE psi.ps_supplycost = (SELECT MAX(ps_supplycost) 
                            FROM PartSupplierInfo 
                            WHERE p_partkey = psi.p_partkey AND availability = 'High')
      AND (sh.level <> 0 OR EXISTS (SELECT 1 FROM orders o WHERE o.o_custkey = co.c_custkey AND o.o_orderstatus = 'O'))
ORDER BY total_spent DESC NULLS LAST, sh.level ASC, c.c_name;
