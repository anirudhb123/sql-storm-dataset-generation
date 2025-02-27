WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS lvl
    FROM supplier
    WHERE s_name LIKE 'Supplier%'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.lvl + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.lvl < 5
),
high_value_orders AS (
    SELECT o_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o_orderkey
    HAVING SUM(l_extendedprice * (1 - l_discount)) > (
        SELECT AVG(l_extendedprice * (1 - l_discount)) 
        FROM lineitem 
        WHERE l_returnflag = 'N'
    )
),
region_summary AS (
    SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
)
SELECT rh.region_name, rh.customer_count, rh.order_count, rh.total_sales,
       COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END), 0) AS return_quantity,
       COUNT(DISTINCT sh.s_suppkey) AS total_suppliers
FROM region_summary rh
LEFT JOIN lineitem l ON EXISTS (
    SELECT 1 FROM high_value_orders hvo WHERE hvo.o_orderkey = l.l_orderkey
)
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey IN (
    SELECT n.n_nationkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
)
GROUP BY rh.region_name, rh.customer_count, rh.order_count, rh.total_sales
ORDER BY rh.total_sales DESC
LIMIT 10;
