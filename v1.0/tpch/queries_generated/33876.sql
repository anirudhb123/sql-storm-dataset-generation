WITH RECURSIVE top_n_nations AS (
    SELECT n_name, n_regionkey, ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY COUNT(DISTINCT s_suppkey) DESC) AS rn
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n_name, n_regionkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, total_spent, order_count
    FROM customer_orders
    WHERE total_spent > 100000
),
part_supply_details AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
region_summary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count, SUM(s.s_acctbal) AS total_acct_bal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT 
    r.r_name AS region,
    COALESCE(n.n_name, 'No Nation') AS nation,
    COALESCE(c.c_name, 'No Customer') AS customer_name,
    CONCAT('Customer: ', COALESCE(c.c_name, 'N/A'), ' spent: ', COALESCE(hv.total_spent, 0), ' in ', r.r_name) AS customer_message,
    p.p_name AS part_name,
    COALESCE(ps.total_available, 0) AS available_quantity,
    COALESCE(ps.avg_supply_cost, 0) AS average_supply_cost,
    n.rn AS nation_rank
FROM region_summary r
LEFT JOIN top_n_nations n ON r.r_name = n.r_name
LEFT JOIN high_value_customers hv ON n.n_name = hv.c_name
LEFT JOIN part_supply_details ps ON ps.p_partkey = (SELECT ps_partkey FROM partsupp ORDER BY RANDOM() LIMIT 1)
LEFT JOIN part p ON ps.p_partkey = p.p_partkey
WHERE r.nation_count > 0
ORDER BY region, nation_rank DESC, available_quantity DESC
LIMIT 15;
