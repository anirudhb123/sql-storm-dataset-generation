WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 0 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderstatus, oh.o_totalprice, oh.o_orderdate, oh.level + 1
    FROM orders oh
    JOIN OrderHierarchy h ON oh.o_orderkey = h.o_orderkey
)

, TotalLineItem AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(l.l_linenumber) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT n.n_name AS nation_name,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       ROUND(AVG(CASE WHEN total_price > 5000 THEN total_price END), 2) AS avg_high_value_order,
       STRING_AGG(DISTINCT p.p_name, ', ') FILTER (WHERE p.p_size >= 10) AS large_parts,
       CASE WHEN SUM(ps.ps_availqty) IS NULL THEN 'Unavailable' ELSE 'Available' END AS part_availability
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN orderHierarchy oh ON c.c_custkey = oh.o_orderkey
LEFT JOIN TotalLineItem tli ON oh.o_orderkey = tli.l_orderkey
WHERE n.n_name LIKE 'A%' AND (p.p_brand = 'Brand#1' OR p.p_brand IS NULL)
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
   AND SUM(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
   AND MAX(tli.item_count) > 5
ORDER BY customer_count DESC;
