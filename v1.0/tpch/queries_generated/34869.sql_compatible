
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), AggregatedParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, l.l_discount, l.l_tax, 
           l.l_extendedprice * (1 - l.l_discount) AS discounted_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
), MonthlySales AS (
    SELECT EXTRACT(MONTH FROM o.o_orderdate) AS month,
           SUM(od.discounted_price) AS total_monthly_sales
    FROM OrderDetails od
    JOIN orders o ON od.o_orderkey = o.o_orderkey
    GROUP BY EXTRACT(MONTH FROM o.o_orderdate)
), CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    p.p_name, 
    rh.r_name, 
    SUM(COALESCE(d.total_monthly_sales, 0)) AS total_sales,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(s.s_acctbal) AS max_supplier_acctbal
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN region rh ON s.s_nationkey = rh.r_regionkey
LEFT JOIN MonthlySales d ON d.month = EXTRACT(MONTH FROM DATE '1998-10-01')
LEFT JOIN CustomerDetails c ON c.total_spent > 100
WHERE p.p_retailprice < 500 AND s.s_comment NOT LIKE '%damaged%'
GROUP BY p.p_name, rh.r_name
ORDER BY total_sales DESC
LIMIT 10;
