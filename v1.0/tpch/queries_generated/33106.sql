WITH RECURSIVE high_value_orders AS (
    SELECT o_orderkey, o_totalprice, o_orderdate, o_orderstatus 
    FROM orders 
    WHERE o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
    UNION ALL
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus 
    FROM orders o 
    INNER JOIN high_value_orders hvo ON o.o_orderkey = hvo.o_orderkey + 1
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
part_stats AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           COUNT(distinct ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_availqty,
           SUM(ps.ps_supplycost) AS total_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
ranked_parts AS (
    SELECT p.*, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.total_cost DESC) AS brand_rank
    FROM part_stats p
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(o.o_totalprice) AS total_order_value,
       SUM(ps.ps_availqty) AS total_parts_available,
       STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN ranked_parts rp ON l.l_partkey = rp.p_partkey
LEFT JOIN supplier_summary s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                               FROM partsupp ps 
                                               WHERE ps.ps_partkey = rp.p_partkey 
                                               ORDER BY ps.ps_supplycost DESC LIMIT 1)
WHERE o.o_orderdate >= '2023-01-01' 
  AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
  AND rp.brand_rank <= 5
GROUP BY r.r_name
HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
  AND COUNT(DISTINCT c.c_custkey) > 0
ORDER BY total_order_value DESC;
