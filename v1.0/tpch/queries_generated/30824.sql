WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS tier
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, sh.tier + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           COALESCE(MAX(os.total_revenue), 0) AS max_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.order_count, c.max_revenue,
           RANK() OVER (ORDER BY c.max_revenue DESC) AS revenue_rank
    FROM CustomerOrders c
)
SELECT r.r_name, COUNT(DISTINCT nc.n_nationkey) AS nation_count,
       AVG(sp.s_acctbal) AS avg_supplier_balance, 
       SUM(tc.max_revenue) AS total_top_customer_revenue
FROM region r
JOIN nation nc ON r.r_regionkey = nc.n_regionkey
JOIN supplier s ON nc.n_nationkey = s.s_nationkey
JOIN SupplierHierarchy sp ON s.s_suppkey = sp.s_suppkey
JOIN TopCustomers tc ON tc.max_revenue > 1000
GROUP BY r.r_name
HAVING COUNT(DISTINCT nc.n_nationkey) > 1
ORDER BY total_top_customer_revenue DESC;
