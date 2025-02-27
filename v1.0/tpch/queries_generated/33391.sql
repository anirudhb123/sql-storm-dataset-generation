WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey != sh.s_suppkey
),
AvgCustBal AS (
    SELECT c_nationkey, AVG(c_acctbal) AS avg_balance
    FROM customer
    GROUP BY c_nationkey
),
LargerOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    nh.n_name,
    AVG(c.avg_balance) AS avg_customer_balance,
    COUNT(DISTINCT so.o_orderkey) AS num_larger_orders,
    SUM(sp.total_available_qty) AS total_available_qty_per_supplier,
    SUM(sp.total_supply_value) AS total_supply_value_per_supplier
FROM nation nh
LEFT JOIN AvgCustBal c ON nh.n_nationkey = c.c_nationkey
LEFT JOIN LargerOrders so ON nh.n_nationkey = (SELECT n1.n_nationkey FROM supplier s1 JOIN nation n1 ON s1.s_nationkey = n1.n_nationkey WHERE s1.s_suppkey IN (SELECT s2.s_suppkey FROM SupplierHierarchy s2))
LEFT JOIN SupplierPerformance sp ON nh.n_nationkey = (SELECT s3.s_nationkey FROM supplier s3 WHERE s3.s_suppkey IN (SELECT s4.s_suppkey FROM SupplierHierarchy s4))
GROUP BY nh.n_name
ORDER BY avg_customer_balance DESC, num_larger_orders DESC;
