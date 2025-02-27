WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name
    FROM PartSupplierStats p
    WHERE p.total_cost > (SELECT AVG(total_cost) FROM PartSupplierStats)
),
RecentOrders AS (
    SELECT DISTINCT o.o_orderkey, o.o_orderdate, l.l_partkey, l.l_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate > CURRENT_DATE - INTERVAL '90 DAY'
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, SUM(p.total_cost) AS regional_part_value,
       COUNT(DISTINCT CASE WHEN c.total_spent > 1000 THEN c.c_custkey END) AS high_value_customers,
       AVG(sh.level) AS average_supplier_level
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN HighValueParts p ON s.s_suppkey = p.p_partkey
LEFT JOIN CustomerOrderSummary c ON s.s_nationkey = c.c_custkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
GROUP BY r.r_name
HAVING regional_part_value IS NOT NULL AND average_supplier_level IS NOT NULL
ORDER BY regional_part_value DESC;
