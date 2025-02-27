WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS hierarchy_level
    FROM nation
    WHERE n_regionkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.hierarchy_level + 1
    FROM nation_hierarchy nh
    JOIN nation n ON nh.n_nationkey = n.n_regionkey
),
supplier_summary AS (
    SELECT s.nationkey, COUNT(s.s_suppkey) AS total_suppliers, SUM(s.s_acctbal) AS total_balance
    FROM supplier s
    GROUP BY s.nationkey
),
part_supply_info AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_orders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
max_order_val AS (
    SELECT MAX(total_order_value) AS max_val FROM customer_orders
),
final_results AS (
    SELECT 
        n.n_name AS nation_name,
        ps.p_name AS part_name,
        ps.total_supply_cost,
        s.total_suppliers,
        s.total_balance,
        co.total_order_value
    FROM nation n
    LEFT JOIN supplier_summary s ON n.n_nationkey = s.nationkey
    LEFT JOIN part_supply_info ps ON n.n_nationkey = ps.p_partkey
    LEFT JOIN customer_orders co ON n.n_nationkey = co.c_custkey
    WHERE (s.total_suppliers IS NOT NULL OR s.total_balance IS NOT NULL)
    AND (co.total_order_value > (SELECT max_val FROM max_order_val) / 10)
)
SELECT nation_name, part_name, total_supply_cost, total_suppliers, total_balance, 
       ROW_NUMBER() OVER (PARTITION BY nation_name ORDER BY total_supply_cost DESC) AS rank
FROM final_results
ORDER BY nation_name, rank;
