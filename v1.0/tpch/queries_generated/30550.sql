WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate, o_orderpriority, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority, level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(oi.total_value) AS total_order_value,
    AVG(oi.average_price) AS average_price,
    COUNT(DISTINCT oi.order_key) AS total_orders
FROM (
    SELECT 
        o.hierarchy_orderkey AS order_key,
        COUNT(DISTINCT l.l_linenumber) AS items_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        AVG(l.l_extendedprice) AS average_price
    FROM OrderHierarchy o
    JOIN lineitem l ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
) AS oi
JOIN customer c ON oi.order_key IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = oi.order_key))
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_order_value DESC;
