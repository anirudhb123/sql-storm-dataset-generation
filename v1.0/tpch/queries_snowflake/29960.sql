
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    REPLACE(s.s_comment, 'pending', 'in progress') AS updated_comment
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size > 10
GROUP BY 
    SUBSTRING(p.p_name, 1, 10),
    CONCAT(r.r_name, ' - ', n.n_name),
    REPLACE(s.s_comment, 'pending', 'in progress')
HAVING SUM(l.l_quantity) > 100
ORDER BY AVG(l.l_extendedprice) DESC, COUNT(DISTINCT ps.ps_suppkey) ASC;
