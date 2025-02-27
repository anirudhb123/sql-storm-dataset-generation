WITH RECURSIVE order_hierarchy AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01' 
    UNION ALL
    SELECT oh.c_custkey, oh.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM order_hierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
order_summary AS (
    SELECT c.c_nationkey, 
           r.r_name AS region_name, 
           SUM(o.o_totalprice) AS total_revenue, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name IS NOT NULL
    GROUP BY c.c_nationkey, r.r_name
),
top_suppliers AS (
    SELECT ps.ps_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
)
SELECT o.region_name, 
       COUNT(DISTINCT oh.o_orderkey) AS total_orders,
       CONCAT('Total Revenue: $', ROUND(SUM(os.total_revenue), 2)) AS revenue_summary,
       COALESCE(MAX(ts.total_cost), 0) AS max_supplier_cost,
       SUM(ts.total_cost) AS total_supplier_cost
FROM order_summary os
LEFT JOIN order_hierarchy oh ON os.c_nationkey = oh.c_custkey
LEFT JOIN top_suppliers ts ON os.c_nationkey = ts.ps_suppkey
WHERE os.total_revenue > 50000
GROUP BY o.region_name
ORDER BY total_orders DESC
FETCH FIRST 10 ROWS ONLY;
