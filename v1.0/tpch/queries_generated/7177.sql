WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_acctbal, 1 AS order_level 
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_acctbal, oh.order_level + 1 
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE oh.order_level < 5
)
SELECT 
    oh.o_orderkey,
    COUNT(DISTINCT l.l_linenumber) AS number_of_line_items,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    c.c_mktsegment,
    n.n_name AS supplier_nation,
    r.r_name AS region_name
FROM OrderHierarchy oh
JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name IN ('AMERICA', 'EUROPE')
GROUP BY oh.o_orderkey, c.c_mktsegment, n.n_name, r.r_name
HAVING total_revenue > 10000
ORDER BY total_revenue DESC, oh.o_orderdate ASC
LIMIT 50;
