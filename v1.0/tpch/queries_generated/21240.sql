WITH RECURSIVE SupplyCostCTE AS (
    SELECT ps_partkey, ps_suppkey, ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rn
    FROM partsupp
), FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           COALESCE(NULLIF(ROUND(MAX(ps.ps_supplycost), 2), 0), 0) AS max_supply_cost
    FROM supplier s
    LEFT JOIN SupplyCostCTE ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey,
           SUM(o.o_totalprice) AS total_spent, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
), OrderDetails AS (
    SELECT co.c_custkey, co.total_spent,
           CASE WHEN COUNT(l.l_orderkey) = 0 THEN NULL ELSE COUNT(l.l_orderkey) END AS total_items
    FROM CustomerOrders co
    LEFT JOIN lineitem l ON co.c_custkey = (
        SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey
    )
    GROUP BY co.c_custkey, co.total_spent
)
SELECT p.p_partkey, p.p_name, 
       r.r_name AS supplier_region, 
       SUM(COALESCE(od.total_items, 0)) AS total_items_ordered,
       AVG(fs.max_supply_cost) AS avg_supply_cost,
       COUNT(DISTINCT fs.s_suppkey) AS unique_suppliers
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
LEFT JOIN region r ON fs.s_nationkey = r.r_regionkey
LEFT JOIN OrderDetails od ON p.p_partkey = (
    SELECT l.l_partkey FROM lineitem l 
    JOIN orders o ON o.o_orderkey = l.l_orderkey
)
GROUP BY p.p_partkey, p.p_name, r.r_name
HAVING AVG(fs.max_supply_cost) > (
    SELECT AVG(ps_supplycost) FROM partsupp
    WHERE ps_supplycost IS NOT NULL
) AND COUNT(DISTINCT fs.s_suppkey) <= (
    SELECT COUNT(DISTINCT s_suppkey) 
    FROM supplier 
    WHERE s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
) - 1
ORDER BY total_items_ordered DESC NULLS LAST, avg_supply_cost ASC;
