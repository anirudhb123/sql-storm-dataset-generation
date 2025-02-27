WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
),
AveragePrice AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
SupplierParts AS (
    SELECT s.s_suppkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 20 AND s.s_acctbal IS NOT NULL
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY o.o_orderkey
)

SELECT 
    rh.s_name AS supplier_name,
    SUM(sp.ps_availqty) AS total_available_qty,
    COUNT(DISTINCT tc.c_custkey) AS number_of_top_customers,
    AVG(ap.avg_cost) AS average_supply_cost,
    COUNT(DISTINCT od.o_orderkey) AS total_orders
FROM SupplierHierarchy rh
LEFT JOIN SupplierParts sp ON rh.s_suppkey = sp.s_suppkey
LEFT JOIN TopCustomers tc ON sp.s_suppkey = tc.c_custkey
LEFT JOIN AveragePrice ap ON sp.p_name = ap.p_partkey
LEFT JOIN OrderDetails od ON sp.s_suppkey = od.o_orderkey
GROUP BY rh.s_name
HAVING SUM(sp.ps_availqty) > 1000 AND COUNT(DISTINCT od.o_orderkey) > 5;
