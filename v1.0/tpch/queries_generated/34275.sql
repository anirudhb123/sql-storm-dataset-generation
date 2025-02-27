WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, CONCAT(sh.s_name, ' -> ', s.s_name), sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 3
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
part_supplier_data AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY AVG(ps.ps_supplycost) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_type
)
SELECT DISTINCT
    r.r_name,
    n.n_name,
    c.c_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(NULLIF(ps.avg_supply_cost, 0)) AS avg_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN part_supplier_data ps ON l.l_partkey = ps.p_partkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE o.o_orderstatus = 'F'
GROUP BY r.r_name, n.n_name, c.c_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY revenue DESC;
