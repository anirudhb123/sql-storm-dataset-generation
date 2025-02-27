WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > (SELECT AVG(total_spent) FROM (
        SELECT SUM(o_totalprice) AS total_spent 
        FROM orders 
        GROUP BY o_custkey
    ) AS avg_spending)
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
FinalGrowth AS (
    SELECT n.n_name AS nation_name, SUM(ps.num_suppliers) AS total_part_suppliers
    FROM PartSupplierStats ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE p.p_mfgr IN (SELECT DISTINCT p_mfgr FROM part WHERE p_size < 20)
    GROUP BY n.n_name
)
SELECT sh.s_name, c.c_name, cg.nation_name, cg.total_part_suppliers 
FROM SupplierHierarchy sh
JOIN TopCustomers c ON sh.s_nationkey = c.c_custkey
JOIN FinalGrowth cg ON cg.total_part_suppliers > 10
ORDER BY cg.total_part_suppliers DESC, sh.s_acctbal DESC;
