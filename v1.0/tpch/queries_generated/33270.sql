WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_product_cost,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    n.n_name AS Nation,
    COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
    SUM(od.total_product_cost) AS TotalSalesValue,
    MAX(od.o_orderdate) AS LastOrderDate,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (Balance: ', c.c_acctbal, ')'), ', ') AS HighAccountBalanceCustomers
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN OrderDetails od ON od.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_suppkey = s.s_suppkey AND l.l_discount > 0.1
)
LEFT JOIN FilteredCustomers c ON c.c_nationkey = n.n_nationkey
WHERE n.n_comment IS NOT NULL
GROUP BY n.n_name
HAVING SUM(od.total_product_cost) > 1000000
ORDER BY TotalSalesValue DESC;
