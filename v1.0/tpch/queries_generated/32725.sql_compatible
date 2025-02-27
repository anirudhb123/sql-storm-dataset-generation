
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_address, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_address, c.c_acctbal + ch.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal IS NOT NULL
), 
TopCustomers AS (
    SELECT c.c_nationkey, SUM(c.c_acctbal) AS total_acctbal
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_nationkey
    HAVING SUM(c.c_acctbal) > 5000
), 
OrderDetails AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           COUNT(l.l_linenumber) AS line_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT r.r_name, 
       COALESCE(tc.total_acctbal, 0) AS total_account_balance, 
       od.total_sales, 
       od.line_count,
       CASE 
           WHEN od.sales_rank = 1 THEN 'Top Sale'
           ELSE 'Regular Sale'
       END AS sale_type
FROM region r
LEFT JOIN TopCustomers tc ON r.r_regionkey = tc.c_nationkey
LEFT JOIN OrderDetails od ON tc.c_nationkey = od.o_orderkey
WHERE r.r_comment IS NOT NULL
ORDER BY r.r_name, total_sales DESC;
