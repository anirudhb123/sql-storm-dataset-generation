WITH RECURSIVE region_hierarchy AS (
    SELECT r.r_regionkey, r.r_name, r.r_comment, 1 AS level
    FROM region r
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region_hierarchy rh
    JOIN nation n ON rh.r_regionkey = n.n_regionkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_part_cost AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
part_statistics AS (
    SELECT p.p_partkey, p.p_name, AVG(l.l_extendedprice) AS avg_price, COUNT(DISTINCT ps.ps_suppkey) AS suppliers_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_parts AS (
    SELECT p.*, RANK() OVER (PARTITION BY p.p_type ORDER BY p.avg_price DESC) AS price_rank
    FROM part_statistics p
)
SELECT rh.r_name, co.c_name, rp.p_name, rp.avg_price, rp.suppliers_count, co.total_orders, co.avg_order_value, 
       sp.total_supply_cost
FROM region_hierarchy rh
JOIN nation n ON rh.r_regionkey = n.n_regionkey
JOIN customer_orders co ON n.n_nationkey = co.c_custkey
JOIN ranked_parts rp ON co.c_custkey = rp.p_partkey
LEFT JOIN supplier_part_cost sp ON rp.p_partkey = sp.s_suppkey
WHERE rp.price_rank <= 10
  AND (sp.total_supply_cost IS NULL OR sp.total_supply_cost > 1000.00)
ORDER BY rh.level, co.avg_order_value DESC, rp.avg_price;
