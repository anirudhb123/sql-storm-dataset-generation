WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_qty, 
           AVG(ps.ps_supplycost) as avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
),
FinalResult AS (
    SELECT ph.p_partkey, ph.p_name, ph.total_available_qty, ph.avg_supply_cost,
           tc.total_spent, COUNT(DISTINCT sh.s_suppkey) AS supplier_count
    FROM PartSummary ph
    LEFT JOIN TopCustomers tc ON ph.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_custkey = tc.c_custkey
    )
    LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = tc.c_nationkey
    WHERE ph.total_available_qty IS NOT NULL
    GROUP BY ph.p_partkey, ph.p_name, ph.total_available_qty, ph.avg_supply_cost, tc.total_spent
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.total_available_qty,
    f.avg_supply_cost,
    f.total_spent,
    COALESCE(f.supplier_count, 0) AS supplier_count,
    CASE 
        WHEN f.total_spent IS NOT NULL THEN 'High Value Customer' 
        ELSE 'Low Value Customer' 
    END AS customer_type
FROM FinalResult f
WHERE f.total_available_qty > 100
ORDER BY f.total_available_qty DESC, f.total_spent DESC
LIMIT 50;
