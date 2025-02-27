WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),

SupplierStats AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),

CustomerPurchases AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY s.s_suppkey, s.s_name
)

SELECT 
    ch.o_orderkey, 
    ch.o_custkey, 
    ch.total_spent, 
    ss.total_cost, 
    rs.s_name AS supplier_name,
    CASE 
        WHEN ch.total_orders > 5 THEN 'High Volume'
        WHEN ch.total_orders BETWEEN 3 AND 5 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS order_volume_category
FROM OrderHierarchy ch
JOIN CustomerPurchases cp ON ch.o_custkey = cp.c_custkey
JOIN SupplierStats ss ON ss.ps_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey = ch.o_orderkey
)
LEFT JOIN RankedSuppliers rs ON rs.revenue_rank = 1 
WHERE rs.revenue IS NOT NULL
ORDER BY ch.o_orderdate DESC, total_spent DESC
LIMIT 100;
