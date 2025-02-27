WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    UNION ALL
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.order_level < 5
),
SupplierStats AS (
    SELECT ps.ps_partkey, 
           s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationPerformance AS (
    SELECT n.n_name, 
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(co.total_spent) AS total_revenue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY n.n_name
)
SELECT np.n_name,
       np.customer_count,
       COALESCE(np.total_revenue, 0) AS total_revenue,
       (SELECT AVG(l.l_extendedprice * (1 - l.l_discount)) 
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
          AND o.o_orderstatus = 'F') AS avg_discounted_price,
       s.total_supply_cost,
       CASE 
           WHEN np.total_revenue IS NULL THEN 'No Revenue'
           ELSE 'Revenue Generated' 
       END AS revenue_status
FROM NationPerformance np
LEFT JOIN SupplierStats s ON np.customer_count > 100
ORDER BY np.total_revenue DESC, np.customer_count DESC;
