WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
), PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), CustomerRevenue AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT p.p_partkey, p.p_name, ps.total_available, ps.avg_supply_cost,
       cr.total_revenue, 
       CASE 
           WHEN cr.total_revenue IS NULL THEN 'No Revenue'
           WHEN cr.total_revenue < 1000 THEN 'Low Revenue'
           ELSE 'High Revenue' 
       END AS revenue_category
FROM part p
LEFT JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerRevenue cr ON cr.total_revenue > 5000
RIGHT JOIN SupplierHierarchy sh ON sh.s_suppkey = ps.ps_partkey
WHERE p.p_size BETWEEN 10 AND 20 
  AND (p.p_comment LIKE '%special%' OR ps.total_available IS NULL)
ORDER BY p.p_partkey
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
