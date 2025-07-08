
WITH RECURSIVE part_price_data AS (
    SELECT p_partkey, p_retailprice, 1 AS depth
    FROM part
    WHERE p_retailprice IS NOT NULL
    
    UNION ALL
    
    SELECT pp.p_partkey, pp.p_retailprice * 0.9, depth + 1
    FROM part_price_data p
    JOIN part pp ON pp.p_partkey = p.p_partkey
    WHERE depth < 5 AND pp.p_retailprice IS NOT NULL
),
supplier_aggregates AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(ps.ps_partkey) AS parts_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_orders AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           CASE 
               WHEN SUM(o.o_totalprice) > 1000 THEN 'VIP'
               ELSE 'Regular'
           END AS customer_type
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
combined_data AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           pp.p_retailprice AS part_price,
           sa.total_available,
           ca.total_spent,
           ca.customer_type,
           ROW_NUMBER() OVER (PARTITION BY pp.p_partkey ORDER BY sa.total_available DESC) AS rn
    FROM partsupp ps
    JOIN part pp ON ps.ps_partkey = pp.p_partkey
    LEFT JOIN supplier_aggregates sa ON sa.s_suppkey = ps.ps_suppkey
    FULL OUTER JOIN customer_orders ca ON ca.c_custkey IS NOT NULL
    WHERE pp.p_type LIKE '%size%'
      AND pp.p_container IS NOT NULL
      AND (pp.p_size > 0 OR pp.p_retailprice IS NULL)
)
SELECT *
FROM combined_data
WHERE rn = 1
  AND (total_spent IS NOT NULL OR customer_type IS NULL)
  AND (part_price - COALESCE(total_available, 0) * 0.05) > 0
ORDER BY part_price DESC, customer_type;
