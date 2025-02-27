WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           1 AS lvl
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.lvl + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND sh.lvl < 10
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, p.p_size,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_size
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedOrders AS (
    SELECT co.*, 
           RANK() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) AS order_rank
    FROM CustomerOrders co
)
SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
       ps.p_partkey, ps.total_available,
       co.total_orders, co.total_spent,
       CASE 
           WHEN co.total_spent IS NULL THEN 'No Orders'
           ELSE 'Orders Placed'
       END AS order_status,
       rh.lvl AS supplier_level
FROM SupplierHierarchy rh
JOIN part p ON p.p_partkey IN (SELECT ps.p_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
LEFT JOIN PartStats ps ON ps.p_partkey = p.p_partkey
LEFT JOIN RankedOrders co ON co.c_custkey = rh.s_nationkey
WHERE rh.lvl < 3
AND (co.total_orders IS NULL OR co.total_spent > 100000.00)
ORDER BY rh.s_suppkey, ps.p_partkey, co.total_spent DESC
LIMIT 50;
