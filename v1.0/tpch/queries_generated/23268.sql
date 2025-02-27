WITH RECURSIVE supplier_costs AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
), 
customer_savings AS (
    SELECT c.c_custkey, 
           CASE 
               WHEN SUM(l.l_extendedprice) IS NULL THEN 0 
               ELSE SUM(l.l_extendedprice) END AS total_expenditure,
           COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM customer c 
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
), 
filtered_suppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM supplier_costs s
    WHERE s.total_supply_cost > (SELECT AVG(total_supply_cost) FROM supplier_costs)
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(cs.total_expenditure, 0) AS total_expenditure,
    count(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(MAX(o.o_orderstatus), 'N/A') AS last_order_status,
    STRING_AGG(DISTINCT fs.s_name, ', ') AS suppliers_used,
    MAX(CASE WHEN ro.price_rank = 1 THEN ro.total_price ELSE NULL END) AS highest_order_value
FROM customer_savings cs
JOIN customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN ranked_orders ro ON o.o_orderkey = ro.o_orderkey
LEFT JOIN filtered_suppliers fs ON fs.s_suppkey IN (
    SELECT l.l_suppkey 
    FROM lineitem l
    WHERE l.l_orderkey = o.o_orderkey
)
GROUP BY c.c_custkey, c.c_name
HAVING SUM(cs.total_expenditure) IS NOT NULL
   AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_orders DESC, total_expenditure ASC
LIMIT 100 OFFSET 20;
