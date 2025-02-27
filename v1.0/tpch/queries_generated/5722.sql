WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS total_parts, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PopularParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING total_quantity_sold > 100
)
SELECT 
    ss.s_name AS supplier_name,
    cs.c_name AS customer_name,
    pp.p_name AS popular_part,
    ss.total_parts AS total_parts_supplied,
    cs.total_order_value AS total_order_value,
    pp.total_quantity_sold AS total_quantity_sold
FROM SupplierStats ss
JOIN CustomerStats cs ON ss.total_supply_cost > 50000
JOIN PopularParts pp ON pp.total_quantity_sold > 500
ORDER BY cs.total_order_value DESC, pp.total_quantity_sold DESC;
