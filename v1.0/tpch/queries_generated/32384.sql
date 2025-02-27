WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_comment, 0 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'GERMANY')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
)
SELECT ph.s_name AS supplier_name, 
       ps.p_name AS part_name, 
       ps.total_available_qty, 
       ps.avg_supply_cost, 
       tc.c_name AS top_customer_name, 
       roi.o_orderkey, 
       roi.o_totalprice, 
       CASE 
           WHEN roi.o_totalprice > 5000 THEN 'High' 
           ELSE 'Normal' 
       END AS price_status
FROM SupplierHierarchy ph
JOIN partsupp ps ON ph.s_suppkey = ps.ps_suppkey
JOIN PartStats ps ON ps.p_partkey = ps.ps_partkey
JOIN TopCustomers tc ON tc.total_spent > ps.total_available_qty 
LEFT JOIN RecentOrders roi ON roi.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '30 days'
)
WHERE ph.level <= 2 AND ps.total_available_qty IS NOT NULL
ORDER BY ps.avg_supply_cost DESC, tc.total_spent DESC;
