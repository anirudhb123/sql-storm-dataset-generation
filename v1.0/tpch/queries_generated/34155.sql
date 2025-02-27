WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    INNER JOIN region_hierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
), customer_order_counts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), aggregated_line_items AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    GROUP BY l.l_orderkey
), supplier_part_values AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(order_count) AS avg_orders_per_customer,
    SUM(lp.total_value) AS total_lineitem_value,
    SUM(sp.total_supply_value) AS total_supplier_value,
    MAX(s.s_acctbal) AS max_supplier_account_balance
FROM region_hierarchy r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN customer_order_counts c ON c.c_custkey = s.s_suppkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN aggregated_line_items lp ON lp.l_orderkey = o.o_orderkey
LEFT JOIN supplier_part_values sp ON sp.ps_partkey = s.s_suppkey
WHERE o.o_orderstatus IN ('F', 'O') 
AND s.s_acctbal IS NOT NULL 
AND r.level >= 0 
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY region_name DESC
LIMIT 5;
