WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 0 AS level
    FROM customer
    WHERE c_custkey = (SELECT MIN(c_custkey) FROM customer)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierInfo AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)
SELECT c.c_name, ch.level, 
       COALESCE(ts.total_sales, 0) AS total_sales, 
       si.total_cost, 
       CASE 
           WHEN ts.total_sales IS NULL THEN 'No Sales'
           WHEN si.total_cost IS NULL THEN 'No Supplier'
           ELSE 'Sales Present'
       END AS sales_status
FROM CustomerHierarchy ch
JOIN customer c ON ch.c_custkey = c.c_custkey
LEFT JOIN TotalSales ts ON ts.o_orderkey = (SELECT o.o_orderkey 
                                             FROM orders o 
                                             WHERE o.o_custkey = c.c_custkey
                                             ORDER BY o.o_orderdate DESC LIMIT 1)
LEFT JOIN SupplierInfo si ON si.s_name = (
    SELECT s.s_name 
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE ps.ps_partkey IN (SELECT l.l_partkey 
                             FROM lineitem l 
                             JOIN orders o ON l.l_orderkey = o.o_orderkey 
                             WHERE o.o_custkey = c.c_custkey)
    GROUP BY s.s_name 
    ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC LIMIT 1)
WHERE ch.level <= 3
ORDER BY ch.level, total_sales DESC;
