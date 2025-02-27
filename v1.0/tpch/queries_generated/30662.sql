WITH RECURSIVE price_hike AS (
    SELECT ps_partkey, ps_supplycost, 1 AS level
    FROM partsupp
    WHERE ps_supplycost > 100.00
    UNION ALL
    SELECT p.ps_partkey, p.ps_supplycost * 1.1, level + 1
    FROM partsupp p
    JOIN price_hike ph ON p.ps_partkey = ph.ps_partkey
    WHERE level < 5
), avg_order_prices AS (
    SELECT o.o_orderkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey, c.c_name
)
SELECT cs.c_name, cs.total_spent, cs.order_count, 
       CASE WHEN cs.order_count = 0 THEN 'No Orders' ELSE 'Active' END AS status,
       COALESCE(ph.ps_supplycost, 0) AS adjusted_supply_cost, apr.avg_price
FROM customer_summary cs
LEFT JOIN price_hike ph ON cs.order_count > 0 AND cs.order_count >= 3
LEFT JOIN avg_order_prices apr ON cs.order_count = apr.o_orderkey
WHERE cs.rank <= 10
ORDER BY cs.total_spent DESC, cs.c_name;
