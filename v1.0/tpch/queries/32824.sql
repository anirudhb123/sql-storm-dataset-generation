
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal)
        FROM customer c2
    )
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           COUNT(l.l_orderkey) AS total_items,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT 
    ns.n_name AS nation_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
    AVG(hvc.c_acctbal) AS avg_acct_balance,
    COUNT(DISTINCT oh.o_orderkey) AS total_orders
FROM nation ns
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey = (
    SELECT o.o_custkey
    FROM OrderStats os
    JOIN orders o ON os.o_orderkey = o.o_orderkey
    WHERE os.sales_rank = 1
    ORDER BY os.total_sales DESC
    LIMIT 1
)
LEFT JOIN OrderStats oh ON oh.o_custkey = hvc.c_custkey
GROUP BY ns.n_name
HAVING SUM(ps.ps_supplycost * ps.ps_availqty) IS NOT NULL
ORDER BY total_supplycost DESC;
