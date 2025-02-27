WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(s.s_name AS varchar(255)) AS full_supplier_name, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT sh.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(CONCAT(sh.full_supplier_name, ' -> ', s.s_name) AS varchar(255)),
           sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5
),
PartStatistics AS (
    SELECT p.p_partkey, 
           SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT s.s_name, 
       sh.full_supplier_name, 
       ps.total_available, 
       ps.avg_supply_cost, 
       co.total_orders, 
       co.total_spent 
FROM SupplierHierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
JOIN PartStatistics ps ON ps.p_partkey IN (
    SELECT ps_partkey 
    FROM partsupp 
    WHERE ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
LEFT JOIN CustomerOrders co ON co.total_orders > 0
WHERE s.s_nationkey IN (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_comment IS NOT NULL
) 
AND COALESCE(co.total_spent, 0) > 1000
ORDER BY s.s_name, co.total_spent DESC;
