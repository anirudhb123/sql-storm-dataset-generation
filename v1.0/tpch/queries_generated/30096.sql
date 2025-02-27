WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
SupplierPerformance AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice) AS total_sales,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       COALESCE(SUM(sp.total_sales), 0) AS region_sales, 
       COUNT(DISTINCT cs.c_custkey) AS distinct_customers,
       AVG(sp.avg_supply_cost) AS average_supply_costs,
       MAX(cs.last_order_date) AS latest_order_date
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierPerformance sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN CustomerSummary cs ON cs.total_spent > 1000
WHERE r.r_comment IS NOT NULL
GROUP BY r.r_name
ORDER BY region_sales DESC
LIMIT 10
UNION ALL
SELECT 'Total', 
       SUM(sp.total_sales), 
       COUNT(DISTINCT cs.c_custkey), 
       AVG(sp.avg_supply_cost), 
       NULL
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.n_nationkey
LEFT JOIN SupplierPerformance sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN CustomerSummary cs ON cs.total_spent > 1000;
