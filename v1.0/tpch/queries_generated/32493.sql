WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 3
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
PartSupplierSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail,
           AVG(ps.ps_supplycost) AS avg_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value,
           COUNT(o.o_orderkey) AS total_orders, 
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
Ranking AS (
    SELECT c.c_custkey, c.c_name, 
           RANK() OVER (ORDER BY co.total_order_value DESC) AS ranking
    FROM CustomerOrderSummary co
    JOIN customer c ON co.c_custkey = c.c_custkey
)
SELECT sh.s_name, TOP.c_name, 
       COALESCE(p.total_avail, 0) AS total_availability, 
       COALESCE(p.avg_cost, 0.00) AS average_supply_cost,
       COALESCE(o.last_order_date, '1900-01-01') AS last_order,
       r.ranking
FROM SupplierHierarchy sh
LEFT JOIN PartSupplierSummary p ON sh.s_suppkey = p.p_partkey
LEFT JOIN TopCustomers TOP ON sh.s_nationkey = TOP.c_custkey
LEFT JOIN CustomerOrderSummary o ON TOP.c_custkey = o.c_custkey
LEFT JOIN Ranking r ON TOP.c_custkey = r.c_custkey
WHERE sh.depth < 2
  AND (sh.s_acctbal IS NOT NULL OR sh.s_nationkey IS NOT NULL)
ORDER BY r.ranking, p.avg_cost DESC
LIMIT 100;
