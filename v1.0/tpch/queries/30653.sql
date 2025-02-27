WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 
           1 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal <= 10000 AND ch.level < 5
),
NationSuppliers AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
OrderStats AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
)
SELECT ch.c_custkey, ch.c_name, n.n_name, ns.supplier_count, 
       os.total_sales, os.order_count, os.last_order_date,
       COALESCE(ch.c_acctbal, 0) AS account_balance,
       ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY os.total_sales DESC) AS sales_rank
FROM CustomerHierarchy ch
JOIN NationSuppliers ns ON ch.c_nationkey = ns.n_nationkey
LEFT JOIN OrderStats os ON ch.c_custkey = os.o_custkey
JOIN nation n ON ch.c_nationkey = n.n_nationkey
WHERE ns.supplier_count > 5
  AND (os.total_sales IS NULL OR os.total_sales > 50000)
ORDER BY n.n_name, sales_rank;
