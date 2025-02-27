
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderStats AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
HighValueCustomer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
NationsWithFlags AS (
    SELECT n.n_nationkey, n.n_name, 
           COALESCE(SUM(CASE WHEN ps.ps_availqty < 10 THEN 1 ELSE 0 END), 0) AS low_supply_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_quantity) AS avg_quantity,
    hvc.total_spent,
    nh.low_supply_count
FROM supplier s
JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN HighValueCustomer hvc ON o.o_custkey = hvc.c_custkey
LEFT JOIN NationsWithFlags nh ON s.s_nationkey = nh.n_nationkey
WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY s.s_name, hvc.total_spent, nh.low_supply_count
HAVING AVG(l.l_quantity) > 15 AND COUNT(DISTINCT o.o_orderkey) > 50
ORDER BY total_orders DESC;
