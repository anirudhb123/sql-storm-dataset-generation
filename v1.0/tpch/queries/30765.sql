WITH RECURSIVE neighboring_nations AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    WHERE n.n_name = 'USA'
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    JOIN neighboring_nations nn ON n.n_regionkey = nn.n_regionkey
    WHERE n.n_nationkey != nn.n_nationkey
), 
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN neighboring_nations nn ON s.s_nationkey = nn.n_nationkey
    JOIN nation n ON nn.n_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_regionkey
),
filter_orders AS (
    SELECT DISTINCT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o1.o_totalprice) 
                             FROM orders o1 WHERE o1.o_orderdate >= '1996-01-01')
)
SELECT p.p_name, 
       COALESCE(SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       ss.s_name,
       ss.total_value
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN filter_orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier_stats ss ON ss.s_suppkey = l.l_suppkey
WHERE p.p_size BETWEEN 10 AND 50 
AND (p.p_comment LIKE '%plastic%' OR p.p_comment IS NULL)
GROUP BY p.p_name, ss.s_name, ss.total_value
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_sales DESC, ss.total_value DESC
LIMIT 10;