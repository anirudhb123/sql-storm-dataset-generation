WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, l.l_partkey, l.l_quantity, l.l_discount,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oh.c_name, l.l_partkey, l.l_quantity, l.l_discount,
           ROW_NUMBER() OVER (PARTITION BY oh.o_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM OrderHierarchy oh
    JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
    WHERE l.l_quantity > 10
)
SELECT p.p_partkey, p.p_name, SUM(oh.l_quantity) AS total_quantity, 
       AVG(oh.o_totalprice) AS avg_order_price, 
       COUNT(DISTINCT oh.o_orderkey) AS order_count,
       CASE 
           WHEN AVG(oh.o_totalprice) > 1000 THEN 'High Value'
           ELSE 'Regular Value'
       END AS order_value_category
FROM OrderHierarchy oh
JOIN partsupp ps ON oh.l_partkey = ps.ps_partkey
JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN nation n ON n.n_nationkey = (SELECT n_nationkey FROM supplier WHERE s_suppkey = ps.ps_suppkey ORDER BY s_suppkey LIMIT 1)
WHERE p.p_size > 10 AND n.n_name IS NOT NULL
GROUP BY p.p_partkey, p.p_name
HAVING SUM(oh.l_quantity) > 100
ORDER BY total_quantity DESC;
