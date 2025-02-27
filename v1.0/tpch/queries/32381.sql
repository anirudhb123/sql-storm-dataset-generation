
WITH RECURSIVE customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'

    UNION ALL

    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer_orders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderdate > co.o_orderdate AND o.o_orderstatus = 'O'
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),
region_details AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nations_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)

SELECT 
    co.c_name,
    COALESCE(SUM(co.o_totalprice), 0) AS total_order_value,
    sr.total_cost AS supplier_cost,
    rg.r_name,
    rg.nations_count,
    CASE WHEN SUM(co.o_totalprice) IS NULL THEN 'No orders' ELSE 'Orders Exist' END AS order_status
FROM customer_orders co
LEFT JOIN supplier_info sr ON co.o_orderkey = sr.s_suppkey
LEFT JOIN region_details rg ON co.c_custkey = rg.nations_count
GROUP BY co.c_name, sr.total_cost, rg.r_name, rg.nations_count
HAVING COALESCE(SUM(co.o_totalprice), 0) > 500
ORDER BY total_order_value DESC;
