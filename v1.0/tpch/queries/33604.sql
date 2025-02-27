WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
),
frequent_customers AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
part_supplier_summary AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
top_nations AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY total_acctbal DESC
    LIMIT 5
)
SELECT
    th.n_name AS nation_name,
    SUM(ps.total_avail_qty) AS total_available,
    AVG(ps.avg_supply_cost) AS avg_supply_cost,
    COALESCE(fc.order_count, 0) AS frequent_customer_orders,
    COUNT(DISTINCT sh.s_suppkey) AS unique_suppliers
FROM top_nations th
LEFT JOIN part_supplier_summary ps ON th.n_nationkey = ps.p_partkey
LEFT JOIN frequent_customers fc ON th.n_nationkey = fc.c_custkey
LEFT JOIN supplier_hierarchy sh ON th.n_nationkey = sh.s_suppkey
GROUP BY th.n_name, fc.order_count
ORDER BY SUM(ps.total_avail_qty) DESC, nation_name;
