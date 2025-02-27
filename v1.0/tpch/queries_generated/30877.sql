WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_custkey, oh.o_orderdate, oh.order_level + 1
    FROM orders oh
    JOIN OrderHierarchy oh_parent ON oh.o_custkey = oh_parent.o_custkey
    WHERE oh.o_orderdate > oh_parent.o_orderdate
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.total_price) AS average_order_value,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) END) AS discounted_sales,
    COUNT(l.l_orderkey) FILTER (WHERE l.l_returnflag = 'R') AS returned_items,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice) DESC) AS sales_rank
FROM nation n
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY sales_rank
LIMIT 5;
