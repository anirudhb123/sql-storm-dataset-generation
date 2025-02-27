WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_suppkey = sh.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(COALESCE(o.o_totalprice, 0)) AS total_order_value,
    AVG(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY n.n_name) AS avg_discounted_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE p.p_size > 20
AND r.r_name LIKE 'Asia%'
AND (s.s_acctbal IS NULL OR s.s_acctbal > 1000)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_order_value DESC;
