WITH RECURSIVE part_supply AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY ps.ps_partkey
), 
top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
), 
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000.00
)
SELECT r.r_name AS region_name, SUM(total_supply_cost) AS supply_cost_total, 
       COUNT(DISTINCT t.s_suppkey) AS supplier_count, 
       AVG(co.total_spent) AS avg_customer_spending
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN top_suppliers t ON s.s_suppkey = t.s_suppkey
JOIN part_supply ps ON t.part_count > 0
JOIN customer_orders co ON co.order_count > 0
GROUP BY r.r_name
ORDER BY supply_cost_total DESC
LIMIT 10;
