
WITH RECURSIVE CTE_Supplier_Hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, ch.level + 1
    FROM supplier s
    JOIN CTE_Supplier_Hierarchy ch ON s.s_nationkey = ch.s_nationkey
    WHERE s.s_acctbal > 10000 AND ch.level < 2
),
OrderInfo AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, oi.total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY oi.total_revenue DESC) AS revenue_rank
    FROM orders o
    JOIN OrderInfo oi ON o.o_orderkey = oi.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(roi.total_revenue) AS total_customer_revenue
    FROM customer c
    JOIN RankedOrders roi ON c.c_custkey = roi.o_custkey
    WHERE roi.revenue_rank <= 3
    GROUP BY c.c_custkey, c.c_name
)
SELECT n.n_name AS nation_name, 
       SUM(tc.total_customer_revenue) AS total_nation_revenue,
       COUNT(DISTINCT tc.c_custkey) AS unique_customers,
       AVG(s.s_acctbal) AS avg_supplier_balance,
       MAX(tc.total_customer_revenue) AS max_customer_revenue
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN TopCustomers tc ON n.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey = tc.c_custkey)
GROUP BY n.n_name
HAVING COUNT(DISTINCT tc.c_custkey) > 5
ORDER BY total_nation_revenue DESC;
