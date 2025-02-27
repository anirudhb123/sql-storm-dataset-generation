WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'

    UNION ALL

    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
)

SELECT 
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY c.c_nationkey) AS avg_revenue_per_nation,
    COALESCE(MAX(s.s_acctbal), 0) AS max_supplier_balance,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part p ON l.l_partkey = p.p_partkey
WHERE c.c_acctbal IS NOT NULL AND l.l_shipdate > CURRENT_DATE - INTERVAL '30 days'
GROUP BY c.c_name, c.c_nationkey
HAVING COUNT(DISTINCT o.o_orderkey) > 5 AND SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
