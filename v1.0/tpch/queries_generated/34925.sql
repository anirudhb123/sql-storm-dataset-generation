WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500.00
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
SuspiciousOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_discount * l.l_extendedprice) AS suspicious_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' OR l.l_discount > 0.10
    GROUP BY o.o_orderkey, o.o_custkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rnk
    FROM customer c
    JOIN orders o ON o.o_custkey = c.c_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT DISTINCT
    ch.c_name AS customer_name,
    ch.total_spent AS total_spent,
    sh.s_name AS supplier_name,
    hv.supply_value AS supplier_value,
    CASE 
        WHEN so.suspicious_amount IS NOT NULL THEN 'Suspicious'
        ELSE 'Normal'
    END AS order_status
FROM CustomerOrders ch
JOIN TopCustomers tc ON ch.c_custkey = tc.c_custkey
LEFT JOIN SupplierHierarchy sh ON sh.level <= 2
LEFT JOIN HighValueSuppliers hv ON hv.s_suppkey = sh.s_suppkey
LEFT JOIN SuspiciousOrders so ON so.o_custkey = ch.c_custkey
WHERE ch.total_spent > 1000
ORDER BY ch.total_spent DESC, hv.supply_value DESC;
