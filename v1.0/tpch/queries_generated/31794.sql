WITH RECURSIVE related_parts AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice, 0 AS level
    FROM part
    WHERE p_size > 10 -- Start with parts larger than size 10
    UNION ALL
    SELECT p.partkey, p.p_name, p.p_brand, p.p_retailprice, rp.level + 1
    FROM part p
    JOIN related_parts rp ON p.p_size < rp.p_size -- Recursive condition
),
supplier_stats AS (
    SELECT s.s_suppkey, COUNT(*) AS total_supply,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_orders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' -- Only completed orders
    GROUP BY c.c_custkey
),
avg_retail_price AS (
    SELECT AVG(p.p_retailprice) AS avg_price
    FROM part p
    WHERE p_retailprice IS NOT NULL
)
SELECT rp.p_name, rp.p_brand, rp.p_retailprice, 
       s.total_supply, s.total_supply_cost, 
       COALESCE(c.total_spent, 0) AS total_spent,
       COALESCE(c.total_orders, 0) AS total_orders,
       CASE 
           WHEN rp.p_retailprice > ar.avg_price THEN 'Above Average' 
           ELSE 'Below Average' 
       END AS price_comparison
FROM related_parts rp
LEFT JOIN supplier_stats s ON s.total_supply > 0
LEFT JOIN customer_orders c ON c.total_spent > 500
CROSS JOIN avg_retail_price ar
WHERE rp.p_retailprice IS NOT NULL
ORDER BY rp.p_retailprice DESC, s.total_supply ASC;
