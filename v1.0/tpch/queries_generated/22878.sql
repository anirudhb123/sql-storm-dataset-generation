WITH ranked_orders AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderdate >= DATE '2022-01-01')
),
part_suppliers AS (
    SELECT p.p_partkey,
           p.p_name,
           s.s_name,
           ps.ps_availqty,
           ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),
customer_orders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
filtered_customers AS (
    SELECT c.c_custkey,
           c.c_name,
           co.total_orders,
           CASE WHEN co.total_orders > 5 THEN 'Frequent' ELSE 'Occasional' END AS customer_type
    FROM customer_orders co
    JOIN customer c ON co.c_custkey = c.c_custkey
)
SELECT r.o_orderkey,
       r.o_orderstatus,
       r.o_orderdate,
       pp.p_name,
       CASE 
           WHEN pp.ps_supplycost IS NULL THEN NULL 
           ELSE pp.ps_supplycost * (1 - CASE WHEN l.l_discount IS NULL THEN 0 ELSE l.l_discount END)
       END AS net_cost,
       fc.customer_type,
       r.rn
FROM ranked_orders r
FULL OUTER JOIN part_suppliers pp ON r.o_orderkey = pp.p_partkey
LEFT JOIN lineitem l ON r.o_orderkey = l.l_orderkey
JOIN filtered_customers fc ON fc.total_orders > 0
WHERE (r.o_orderstatus = 'O' OR pp.ps_supplycost IS NOT NULL)
  AND (fc.c_name LIKE 'A%' OR fc.total_spent > 1000)
  AND COALESCE(r.rn, 0) < 10
ORDER BY r.o_orderdate DESC, net_cost DESC;
