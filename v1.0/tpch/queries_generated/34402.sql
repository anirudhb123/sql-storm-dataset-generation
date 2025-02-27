WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_name LIKE 'S%'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supplier_summary AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
high_value_customers AS (
    SELECT cus.c_custkey, cus.c_name
    FROM customer_order_summary cus
    WHERE cus.total_spent > 10000
),
supplier_performance AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(line.l_extendedprice * (1 - line.l_discount)) AS revenue,
    AVG(s_performance.avg_supply_cost) AS avg_supply_cost,
    COUNT(DISTINCT high.c_custkey) AS high_value_customers_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN lineitem line ON line.l_suppkey = s.s_suppkey
LEFT JOIN orders o ON line.l_orderkey = o.o_orderkey
LEFT JOIN high_value_customers high ON o.o_custkey = high.c_custkey
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY region_name, nation_name;
