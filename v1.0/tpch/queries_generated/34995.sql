WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderpriority, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    WHERE o_orderdate >= DATE '2022-01-01'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
TotalRevenue AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' 
      AND l.l_shipdate >= DATE '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
)
SELECT COALESCE(oh.o_orderkey, 0) AS order_key,
       c.c_name AS customer_name,
       COALESCE(tr.total_revenue, 0) AS revenue,
       COALESCE(sd.total_supplycost, 0) AS supply_cost,
       CASE WHEN tr.total_revenue IS NOT NULL AND sd.total_supplycost IS NOT NULL THEN 
           ROUND(tr.total_revenue / sd.total_supplycost, 2) 
       ELSE NULL END AS revenue_to_cost_ratio,
       oh.order_rank
FROM OrderHierarchy oh
FULL OUTER JOIN TotalRevenue tr ON oh.o_custkey = tr.c_custkey
FULL OUTER JOIN SupplierDetails sd ON sd.s_acctbal BETWEEN 1000 AND 5000
    AND tr.total_revenue IS NULL
LEFT JOIN nation n ON n.n_nationkey = (
    SELECT DISTINCT c_nationkey 
    FROM customer 
    WHERE c_custkey = oh.o_custkey 
      AND c_acctbal IS NOT NULL
)
WHERE n.n_comment IS NOT NULL
ORDER BY order_key, revenue DESC NULLS LAST;
