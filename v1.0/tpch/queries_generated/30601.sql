WITH RECURSIVE OrderCTE AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    JOIN OrderCTE oc ON o.o_orderkey = oc.o_orderkey + 1
)
SELECT r.r_name AS region, 
       n.n_name AS nation, 
       SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS total_sales,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(o.o_totalprice) AS avg_order_value,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_ranking
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN OrderCTE o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE n.n_name IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY region, total_sales DESC;
