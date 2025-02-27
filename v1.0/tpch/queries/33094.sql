
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name AS supp_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT ph.supp_name, ps.p_name, ps.total_avail_qty, co.total_spent
FROM SupplierHierarchy ph
JOIN PartStats ps ON ph.s_suppkey = ps.supplier_count
JOIN CustomerOrders co ON ph.s_nationkey = co.c_custkey
WHERE ps.total_avail_qty > 100 AND co.order_rank <= 10
ORDER BY co.total_spent DESC, ps.total_avail_qty ASC;
