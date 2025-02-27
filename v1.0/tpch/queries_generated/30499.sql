WITH RECURSIVE order_totals AS (
    SELECT o_orderkey, 
           SUM(l_extendedprice * (1 - l_discount)) AS total_price
    FROM orders
    JOIN lineitem ON o_orderkey = l_orderkey
    GROUP BY o_orderkey
), 
ranked_orders AS (
    SELECT o_orderkey,
           total_price,
           RANK() OVER (ORDER BY total_price DESC) AS price_rank
    FROM order_totals
), 
supplier_part_summary AS (
    SELECT s_name, 
           p_name, 
           SUM(ps_availqty) AS total_available_quantity,
           AVG(ps_supplycost) AS avg_supply_cost
    FROM supplier 
    JOIN partsupp ON s_suppkey = ps_suppkey
    JOIN part ON ps_partkey = p_partkey
    GROUP BY s_name, p_name
), 
high_supply_parts AS (
    SELECT s_name, 
           p_name, 
           total_available_quantity, 
           avg_supply_cost
    FROM supplier_part_summary
    WHERE total_available_quantity > (
        SELECT AVG(total_available_quantity) 
        FROM supplier_part_summary
    )
), 
customer_orders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT co.c_name AS customer_name, 
       sop.p_name AS product_name, 
       sop.total_available_quantity,
       r.price_rank,
       r.total_price 
FROM high_supply_parts sop
JOIN ranked_orders r ON sop.p_name = r.total_price
JOIN customer_orders co ON sop.s_name = co.c_name
WHERE r.price_rank <= 10 
  AND sop.avg_supply_cost < (
      SELECT AVG(avg_supply_cost) 
      FROM supplier_part_summary
      WHERE total_available_quantity IS NOT NULL
  )
ORDER BY co.customer_name, r.total_price DESC;
