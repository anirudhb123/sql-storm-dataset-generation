WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, p.p_name, s.s_name AS supplier_name, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT c.c_name, SUM(co.o_totalprice) AS total_order_value, STRING_AGG(DISTINCT psi.supplier_name) AS suppliers,
       COUNT(DISTINCT psi.ps_partkey) AS unique_parts, AVG(psi.ps_supplycost) AS avg_supply_cost,
       MAX(co.o_orderdate) AS last_order_date
FROM CustomerOrders co
JOIN Customer c ON co.c_custkey = c.c_custkey
LEFT JOIN PartSupplierInfo psi ON co.o_orderkey = 
    (SELECT o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
GROUP BY c.c_name
HAVING AVG(psi.ps_supplycost) IS NOT NULL AND SUM(co.o_totalprice) > 5000
ORDER BY total_order_value DESC
LIMIT 10;
