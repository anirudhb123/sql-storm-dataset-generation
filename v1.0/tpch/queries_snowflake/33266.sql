
WITH SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           COALESCE(SUM(p.ps_supplycost * p.ps_availqty), 0) AS total_cost
    FROM supplier s
    LEFT JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, 
           sh.total_cost + COALESCE(SUM(p.ps_supplycost * p.ps_availqty), 0)
    FROM SupplierHierarchy sh
    LEFT JOIN partsupp p ON sh.s_suppkey = p.ps_suppkey
    GROUP BY sh.s_suppkey, sh.s_name, sh.s_acctbal, sh.total_cost
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(os.total_revenue) AS revenue
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    LEFT JOIN orders o ON os.o_orderkey = o.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.order_count, c.revenue,
           RANK() OVER (ORDER BY c.revenue DESC) AS revenue_rank
    FROM CustomerSummary c
    WHERE c.revenue IS NOT NULL AND c.revenue > 
          (SELECT AVG(revenue) FROM CustomerSummary)
)
SELECT n.n_name AS nation_name, 
       COUNT(DISTINCT h.c_custkey) AS high_value_customer_count, 
       AVG(h.revenue) AS avg_revenue
FROM HighValueCustomers h
JOIN nation n ON EXISTS (SELECT 1 FROM customer c WHERE c.c_custkey = h.c_custkey AND c.c_nationkey = n.n_nationkey)
WHERE h.revenue_rank <= 10
GROUP BY n.n_name
ORDER BY avg_revenue DESC
LIMIT 5;
