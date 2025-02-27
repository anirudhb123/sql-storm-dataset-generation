WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 
           1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 
           oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey 
    WHERE o.o_orderdate > oh.o_orderdate
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(oh.o_totalprice) AS total_spent,
           COUNT(oh.o_orderkey) AS total_orders, 
           MAX(oh.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierProduct AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, p.p_retailprice
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
RevenueAnalysis AS (
    SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           s.s_suppkey, s.s_name
    FROM lineitem l
    JOIN SupplierProduct sp ON l.l_partkey = sp.ps_partkey
    JOIN supplier s ON sp.s_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT c.c_name, 
       COALESCE(cos.total_spent, 0) AS total_spent,
       COALESCE(cos.total_orders, 0) AS total_orders,
       COALESCE(cos.last_order_date, 'No Orders') AS last_order_date,
       ra.total_revenue
FROM CustomerOrderSummary cos
FULL OUTER JOIN RevenueAnalysis ra ON cos.c_custkey = ra.s_suppkey
WHERE cos.total_orders > 5 OR ra.total_revenue IS NOT NULL
ORDER BY total_spent DESC NULLS LAST, total_orders DESC;
