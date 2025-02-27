WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
)
SELECT 
    n.n_name AS nation,
    SUM(COALESCE(cs.total_orders, 0)) AS total_orders,
    SUM(COALESCE(cs.total_spent, 0)) AS total_spent,
    AVG(COALESCE(ps.ps_supplycost, 0)) AS avg_supply_cost,
    MAX(COALESCE(ps.ps_availqty, 0)) AS max_avail_qty,
    COUNT(DISTINCT sh.s_suppkey) AS unique_suppliers
FROM nation n
LEFT JOIN CustomerOrderSummary cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN PartSupplier ps ON ps.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 10)
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'EUROPE%')
GROUP BY n.n_name
HAVING SUM(COALESCE(cs.total_spent, 0)) > 50000
ORDER BY total_orders DESC, nation;
