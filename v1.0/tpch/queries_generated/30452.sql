WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS hierarchy_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.hierarchy_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name AS customer_name,
    cs.total_spent,
    cs.order_count,
    COALESCE(SUM(l.revenue), 0) AS total_revenue,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    rh.hierarchy_level
FROM CustomerStats cs
JOIN customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN LineItemDetails l ON c.c_custkey = l.l_orderkey
LEFT JOIN SupplierStats ss ON l.l_orderkey = ss.s_suppkey
JOIN OrderHierarchy rh ON c.c_custkey = rh.o_orderkey
WHERE (cs.total_spent IS NOT NULL OR ss.avg_supply_cost IS NOT NULL)
GROUP BY c.c_name, cs.total_spent, cs.order_count, ss.avg_supply_cost, rh.hierarchy_level
ORDER BY total_spent DESC, total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
