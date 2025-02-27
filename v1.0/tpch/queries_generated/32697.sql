WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level 
    FROM supplier 
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1 
    FROM supplier s 
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT c.c_name, coalesce(s.sm_suppliers, 0) AS supplier_count, 
       coalesce(co.order_count, 0) AS order_count, 
       coalesce(co.total_spent, 0) AS total_spent,
       hp.p_name, hp.p_retailprice, 
       pss.total_supply_cost
FROM CustomerOrders co
FULL OUTER JOIN (
    SELECT COUNT(DISTINCT sh.s_suppkey) AS sm_suppliers, sh.s_nationkey
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
) s ON co.c_mktsegment = (SELECT DISTINCT c_mktsegment FROM customer WHERE c_nationkey = s.s_nationkey)
LEFT JOIN HighValueParts hp ON co.order_count > 5 AND hp.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN supplier su ON ps.ps_suppkey = su.s_suppkey
    WHERE su.s_acctbal > 10000
)
LEFT JOIN PartSupplierSummary pss ON hp.p_partkey = pss.ps_partkey
WHERE (coalesce(s.sm_suppliers, 0) > 0 OR co.order_count IS NOT NULL)
ORDER BY total_spent DESC, supplier_count DESC;
