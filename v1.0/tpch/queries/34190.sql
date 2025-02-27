WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, 1 AS order_level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON oh.o_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND oh.order_level < 5
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT l.l_partkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns
    FROM lineitem l
    WHERE l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY l.l_partkey
)

SELECT cs.c_name, cs.total_orders, cs.total_spent,
       COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
       COALESCE(l.avg_revenue, 0) AS avg_revenue,
       COALESCE(l.total_returns, 0) AS total_returns
FROM CustomerSummary cs
LEFT JOIN SupplierPerformance sp ON cs.total_orders > 10
LEFT JOIN LineItemStats l ON cs.c_custkey = l.l_partkey
WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
ORDER BY cs.total_spent DESC
LIMIT 100;