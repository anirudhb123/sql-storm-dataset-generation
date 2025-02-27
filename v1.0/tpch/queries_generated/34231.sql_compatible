
WITH RECURSIVE CTE_Supplier_Orders AS (
    SELECT s.s_suppkey, s.s_name, COUNT(o.o_orderkey) AS total_orders
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
    UNION ALL
    SELECT s.s_suppkey, s.s_name, COUNT(o.o_orderkey) + c.total_orders
    FROM supplier s
    INNER JOIN CTE_Supplier_Orders c ON s.s_suppkey = c.s_suppkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE c.total_orders < 10
    GROUP BY s.s_suppkey, s.s_name, c.total_orders
),
RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank,
           CASE 
               WHEN o.o_totalprice IS NULL THEN 'Unknown'
               ELSE CASE 
                   WHEN o.o_totalprice > 500 THEN 'High'
                   WHEN o.o_totalprice BETWEEN 200 AND 500 THEN 'Medium'
                   ELSE 'Low'
               END 
           END AS price_category
    FROM orders o
    WHERE o.o_orderstatus = 'O'
)
SELECT 
    p.p_name,
    s.s_name,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS average_order_value,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    r.price_category
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN RankedOrders r ON o.o_orderkey = r.o_orderkey
WHERE p.p_retailprice BETWEEN 10 AND 100
  AND s.s_acctbal IS NOT NULL
  AND l.l_discount > 0.05
GROUP BY p.p_name, s.s_name, r.price_category
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC
LIMIT 100;
