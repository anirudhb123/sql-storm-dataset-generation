WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RegionStats AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_available,
    ps.avg_supply_cost,
    co.order_count,
    co.total_spent,
    rh.nation_count,
    ROW_NUMBER() OVER (PARTITION BY rh.nation_count ORDER BY ps.total_available DESC) AS rank,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.total_spent > 5000 THEN 'High Spender'
        WHEN co.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM PartStatistics ps
JOIN CustomerOrders co ON ps.p_partkey = co.c_custkey
LEFT JOIN RegionStats rh ON co.c_custkey = rh.r_regionkey
WHERE ps.total_available > 50
ORDER BY ps.avg_supply_cost DESC, co.order_count DESC
LIMIT 100;
