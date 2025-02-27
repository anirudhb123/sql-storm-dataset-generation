WITH StringProcessor AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'special', 'modified') AS modified_comment,
        CONCAT(p.p_name, ' - ', p.p_mfgr) AS full_description
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE LENGTH(p_comment) > 15)
)
SELECT 
    s.s_suppkey,
    s.s_name,
    s.s_phone,
    c.c_name,
    COUNT(DISTINCT ps.ps_partkey) AS part_count,
    AVG(o.o_totalprice) AS avg_order_price,
    STRING_AGG(sp.full_description, '; ') AS all_descriptions
FROM StringProcessor sp
JOIN partsupp ps ON sp.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN customer c ON s.s_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
WHERE LENGTH(sp.modified_comment) > 30
GROUP BY s.s_suppkey, s.s_name, s.s_phone, c.c_name
HAVING COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY avg_order_price DESC
LIMIT 10;
