WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name, ' | Customer: ', c.c_name) AS combined_info,
        LENGTH(CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name, ' | Customer: ', c.c_name)) AS info_length,
        LEFT(p.p_comment, 10) AS comment_excerpt
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    WHERE LENGTH(p.p_name) > 20
    ORDER BY info_length DESC
)
SELECT 
    COUNT(*) AS total_records,
    AVG(info_length) AS average_length,
    MAX(info_length) AS max_length,
    MIN(info_length) AS min_length
FROM StringProcessing;
