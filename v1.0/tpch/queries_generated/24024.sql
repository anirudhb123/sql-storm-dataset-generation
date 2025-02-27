WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, CAST(s.s_name AS varchar(255)) AS path, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, CAST(sh.path || ' -> ' || s.s_name AS varchar(255)), sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartStats AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerPurchase AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, total_spent, total_orders,
           RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM CustomerPurchase c
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.total_suppliers, 0) AS suppliers_count,
    COALESCE(ps.total_available, 0) AS available_qty,
    COALESCE(ps.avg_supply_cost, NULL) AS avg_cost,
    tc.c_custkey,
    tc.c_name,
    tc.total_spent,
    tc.total_orders,
    sh.path AS supplier_path
FROM PartStats ps
FULL OUTER JOIN TopCustomers tc ON ps.p_partkey = tc.c_custkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = tc.c_custkey
WHERE (ps.total_available IS NOT NULL OR tc.total_orders IS NOT NULL)
  AND (ps.total_suppliers > 10 OR (tc.total_orders < 5 AND tc.total_spent IS NOT NULL))
ORDER BY p.p_partkey, CASE WHEN ps.total_available IS NULL THEN 1 ELSE 0 END, tc.total_spent DESC;
