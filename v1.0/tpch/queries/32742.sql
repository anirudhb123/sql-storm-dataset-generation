WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3 AND s.s_acctbal < sh.s_acctbal
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, 
           COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    WHERE ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT p.p_name, 
       p.p_retailprice, 
       COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
       ps.total_suppliers, 
       ps.total_avail_qty,
       cs.total_spent AS customer_spending,
       cs.spend_rank
FROM part p
LEFT JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy s ON ps.total_suppliers > 10 AND s.s_suppkey = ps.ps_partkey
LEFT JOIN CustomerOrderStats cs ON ps.total_suppliers = cs.total_orders
WHERE p.p_retailprice > 50.00
  AND (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
ORDER BY p.p_retailprice DESC, cs.total_spent DESC
LIMIT 100;
