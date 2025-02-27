WITH string_benchmark AS (
    SELECT 
        p_partkey,
        SUBSTRING(p_name, 1, 20) AS short_name,
        REPLACE(p_comment, 'special', 'ordinary') AS updated_comment,
        CONCAT('Brand: ', p_brand, ', Type: ', p_type) AS combined_info
    FROM part
    WHERE LENGTH(p_name) > 10
), nation_info AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sb.short_name,
    sb.updated_comment,
    sb.combined_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice) AS total_revenue
FROM string_benchmark sb
JOIN partsupp ps ON sb.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN customer c ON s.s_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN nation_info ni ON s.s_nationkey = ni.n_nationkey
WHERE sb.updated_comment LIKE '%ordinary%'
GROUP BY sb.short_name, sb.updated_comment, sb.combined_info
ORDER BY total_revenue DESC
LIMIT 10;
