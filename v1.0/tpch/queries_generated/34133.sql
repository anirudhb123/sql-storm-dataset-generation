WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(s.s_name AS VARCHAR(100)) AS hierarchy_path, 1 AS level
    FROM supplier s
    WHERE s.s_suppkey < 10  -- Starting with the first 10 suppliers for demo purposes

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(sh.hierarchy_path, ' -> ', s.s_name), 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey > sh.s_suppkey
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > 10000
),
SupplierAvgCost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT n.n_name AS nation_name,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       SUM(os.total_revenue) AS total_revenue,
       MAX(t.total_spent) AS highest_customer_spent,
       AVG(sac.avg_supply_cost) AS average_supply_cost
FROM nation n
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN OrderStats os ON os.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderstatus = 'O'
    AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
LEFT JOIN TopCustomers t ON t.c_custkey = sh.s_suppkey
LEFT JOIN SupplierAvgCost sac ON sac.ps_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps
    WHERE ps.ps_availqty IS NULL OR ps.ps_supplycost > 500.00
)
GROUP BY n.n_name
ORDER BY supplier_count DESC, total_revenue DESC;
