
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    o.o_orderdate AS order_date,
    STRING_AGG(CONCAT('LineItem: ', l.l_linenumber, ' Qty:', l.l_quantity, ' Price:', l.l_extendedprice) ORDER BY l.l_linenumber) AS line_items_summary,
    STRING_AGG(DISTINCT s.s_comment, ' | ') AS supplier_comments,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    r.r_name AS region_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE p.p_name LIKE '%abr%'
AND r.r_name IN ('ASIA', 'EUROPE')
GROUP BY p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate, r.r_name
HAVING COUNT(DISTINCT l.l_linenumber) > 2
ORDER BY r.r_name, o.o_orderdate DESC;
