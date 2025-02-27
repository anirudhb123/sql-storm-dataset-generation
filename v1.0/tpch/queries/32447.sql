
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           NULL AS parent_suppkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           sh.s_suppkey AS parent_suppkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= 10000
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spending,
           c.c_nationkey
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey
),
NationMetrics AS (
    SELECT n.n_nationkey, n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ph.level,
    cm.c_name, 
    cm.total_orders, 
    cm.total_spending,
    ps.total_available, 
    ps.total_supply_cost,
    nm.total_suppliers,
    nm.total_acctbal,
    CASE 
        WHEN cm.total_spending IS NULL THEN 'No Orders'
        WHEN cm.total_spending > 100000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM CustomerOrders cm
JOIN PartStats ps ON ps.total_available > 500
LEFT JOIN NationMetrics nm ON cm.c_nationkey = nm.n_nationkey
INNER JOIN SupplierHierarchy ph ON ph.s_suppkey = nm.total_suppliers
WHERE ps.total_supply_cost IS NOT NULL
ORDER BY customer_segment DESC, cm.total_spending DESC;
