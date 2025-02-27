SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT('Region: ', r.r_name, ' | Comment: ', r.r_comment) AS region_details
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey 
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE p.p_name LIKE 'Multi%'
    AND s.s_comment NOT LIKE '%special%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY p.p_name, s.s_name, r.r_name, r.r_comment
ORDER BY total_available_quantity DESC, avg_extended_price ASC;