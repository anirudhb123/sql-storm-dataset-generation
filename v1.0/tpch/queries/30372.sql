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
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_cost_per_supplier
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT ns.n_name AS nation_name, 
       SUM(COALESCE(sh.level, 0)) AS total_supplier_levels, 
       SUM(cs.total_orders) AS total_orders_by_nation,
       SUM(cs.total_spent) AS total_spent_by_nation,
       ps.total_available, 
       ps.avg_cost_per_supplier
FROM nation ns
LEFT JOIN SupplierHierarchy sh ON ns.n_nationkey = sh.s_nationkey
LEFT JOIN CustomerOrderStats cs ON ns.n_nationkey = cs.c_custkey
JOIN PartSupplierStats ps ON ps.p_partkey IN (
    SELECT ps_partkey 
    FROM partsupp 
    WHERE ps_supplycost < 50
)
GROUP BY ns.n_name, ps.total_available, ps.avg_cost_per_supplier
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY total_spent_by_nation DESC;
