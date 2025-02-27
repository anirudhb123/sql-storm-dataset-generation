WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey,
           s_acctbal,
           CAST(s_name AS varchar(255)) AS hierarchy_path
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           s.s_acctbal,
           CAST(CONCAT(sh.hierarchy_path, ' -> ', s.s_name) AS varchar(255))
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal < sh.s_acctbal
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_availqty) AS total_available,
           MAX(ps.ps_supplycost) AS max_supply_cost,
           MIN(ps.ps_supplycost) AS min_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT cs.c_name, cs.total_orders, cs.total_spent,
       ps.p_name, ps.total_available, 
       CASE 
           WHEN ps.max_supply_cost IS NULL THEN 'No Supply'
           ELSE FORMAT(ps.max_supply_cost, 'C') 
       END AS max_supply_cost_formatted,
       ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS customer_rank
FROM CustomerOrderStats cs
LEFT JOIN PartSupplierStats ps ON cs.total_spent > 1000
WHERE cs.order_rank = 1
ORDER BY cs.total_spent DESC NULLS LAST;


