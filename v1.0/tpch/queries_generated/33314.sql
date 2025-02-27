WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'UNITED STATES')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY c.c_custkey, c.c_name
),
PartStats AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name,
    sh.s_name AS supplier_name,
    us.total_spent,
    ps.p_partkey,
    ps.supplier_count,
    ps.avg_supply_cost,
    CASE 
        WHEN us.total_spent IS NULL THEN 'No Orders'
        WHEN us.total_spent < 1000 THEN 'Low Spender'
        WHEN us.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM region r
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = r.r_regionkey
LEFT JOIN OrderSummary us ON us.c_custkey = sh.s_suppkey
JOIN PartStats ps ON ps.supplier_count > 5 
WHERE r.r_name IS NOT NULL 
AND ps.avg_supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY r.r_name, us.total_spent DESC NULLS LAST;
