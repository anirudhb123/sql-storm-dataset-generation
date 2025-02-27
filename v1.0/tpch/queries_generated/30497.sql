WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
)
SELECT n.n_name, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       SUM(ps.total_available) AS total_parts_available,
       AVG(ps.avg_supply_cost) AS average_cost_per_part,
       COALESCE(SUM(cs.total_orders), 0) AS total_customer_orders,
       COALESCE(SUM(cs.total_spent), 0) AS total_spent_by_customers
FROM nation n
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN PartSupplierStats ps ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = sh.s_suppkey)
LEFT JOIN CustomerOrderStats cs ON n.n_nationkey = cs.c_nationkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY supplier_count DESC, n.n_name;
