WITH RECURSIVE SupplierHierarchy AS (
    SELECT s1.s_suppkey, s1.s_name, s1.s_nationkey, 1 AS level
    FROM supplier s1
    WHERE s1.s_nationkey IS NOT NULL
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(l.l_orderkey) AS item_count,
           AVG(o.o_totalprice) OVER (PARTITION BY o.o_orderstatus) AS avg_order_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY o.o_orderkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation, 
    SUM(os.total_sales) AS total_revenue,
    COUNT(DISTINCT os.o_orderkey) AS unique_orders,
    STRING_AGG(DISTINCT sh.s_name, ', ') AS supplier_names,
    COUNT(CASE WHEN os.item_count >= 5 THEN 1 END) AS high_item_orders,
    MAX(os.avg_order_price) AS max_avg_price
FROM OrderSummary os
JOIN customer c ON os.o_orderkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN TopSuppliers ts ON sh.s_suppkey = ts.s_suppkey
WHERE os.total_sales IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING SUM(os.total_sales) > 10000
ORDER BY total_revenue DESC;
