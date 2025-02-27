
SELECT 
    s.s_name,
    COUNT(o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_type, ', ') AS part_types,
    STRING_AGG(DISTINCT SUBSTRING(s.s_comment, 1, 20), '; ') AS supplier_comments_preview
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderstatus = 'O'
AND l.l_shipdate >= '1997-01-01'
AND l.l_shipdate <= '1997-12-31'
GROUP BY s.s_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY total_revenue DESC;
