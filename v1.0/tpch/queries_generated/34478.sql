WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey,
           1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oh.o_custkey,
           oh.order_level + 1
    FROM orders oh
    JOIN OrderHierarchy oh_parent ON oh.o_custkey = oh_parent.o_custkey
    WHERE oh.o_orderdate > oh_parent.o_orderdate
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discount_total,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END) AS avg_returned_quantity,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
WHERE o.o_orderstatus = 'O'
  AND l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
  AND (p.p_container LIKE '%BOX%' OR p.p_size IS NULL)
  AND n.n_comment IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING total_customers > 10
ORDER BY rank;
