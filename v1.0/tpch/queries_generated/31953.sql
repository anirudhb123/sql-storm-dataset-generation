WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier AS sp
    JOIN SupplierHierarchy AS sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > 5000
),
RelevantCustomers AS (
    SELECT c_customer.c_custkey, c_name, c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) AS Rank
    FROM customer AS c_customer
    WHERE c_acctbal IS NOT NULL AND c_acctbal > 5000
),
OrderStats AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           MAX(o.o_orderdate) AS last_order_date
    FROM orders AS o
    JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp AS ps
    JOIN SupplierHierarchy AS sh ON ps.ps_suppkey = sh.s_suppkey
    GROUP BY ps.ps_suppkey
)
SELECT RANK() OVER (ORDER BY o.total_spent DESC) AS spending_rank,
       c.c_name, c.c_acctbal, o.total_spent, o.order_count, o.last_order_date,
       ts.total_supply_cost
FROM RelevantCustomers AS c
JOIN OrderStats AS o ON c.c_custkey = o.o_custkey
LEFT OUTER JOIN TopSuppliers AS ts ON ts.ps_suppkey = c.c_custkey
WHERE c.Rank <= 10 AND (o.last_order_date IS NOT NULL OR ts.total_supply_cost IS NOT NULL)
ORDER BY spending_rank;
