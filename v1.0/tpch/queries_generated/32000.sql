WITH RECURSIVE cust_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM cust_orders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderdate > co.o_orderdate
),
supplier_part AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
aggregated_data AS (
    SELECT co.c_custkey, co.c_name, SUM(co.o_totalprice) AS total_spent,
           AVG(sp.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT co.o_orderkey) AS order_count
    FROM cust_orders co
    LEFT JOIN supplier_part sp ON co.o_orderkey = sp.ps_partkey
    GROUP BY co.c_custkey, co.c_name
),
ranked_customers AS (
    SELECT custkey, name, total_spent, avg_supply_cost, order_count,
           RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM aggregated_data
)
SELECT rc.rank, rc.name, rc.total_spent, rc.avg_supply_cost, rc.order_count,
       CASE WHEN rc.order_count > 10 THEN 'High Value' ELSE 'Low Value' END AS customer_category
FROM ranked_customers rc
WHERE rc.rank <= 10
ORDER BY rc.total_spent DESC;

