WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate > '2023-01-01')
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS supplier_count, SUM(ps.ps_availqty) AS total_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RegionStats AS (
    SELECT r.r_name, AVG(s.s_acctbal) AS avg_acctbal, COUNT(s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS open_orders,
    (SELECT COUNT(*) FROM HighValueOrders) AS high_value_order_count,
    (SELECT MAX(total_spent) FROM CustomerOrders) AS highest_spent_customer,
    SUM(COALESCE(ps.total_avail_qty, 0)) AS total_availability,
    AVG(sh.depth) AS avg_supplier_depth
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.n_nationkey
LEFT JOIN CustomerOrders c ON s.s_suppkey = c.c_custkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN PartSupplier ps ON ps.p_partkey = (SELECT p.p_partkey FROM part p ORDER BY RANDOM() LIMIT 1)
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
GROUP BY r.r_name
HAVING AVG(s.s_acctbal) > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
ORDER BY total_customers DESC
LIMIT 10;
