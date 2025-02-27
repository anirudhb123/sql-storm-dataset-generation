WITH StringMetrics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        CHAR_LENGTH(p.p_comment) AS comment_length,
        REGEXP_COUNT(p.p_comment, 'excellent') AS excellent_count,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS clean_comment,
        LOWER(p.p_name) AS lower_name,
        UPPER(p.p_name) AS upper_name,
        SUBSTR(p.p_name, 1, 10) AS name_prefix
    FROM part p
),
SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        REPLACE(s.s_address, ' ', '-') AS formatted_address,
        LENGTH(s.s_comment) AS comment_length,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, s.s_comment
)
SELECT 
    sm.p_partkey,
    sm.p_name,
    sm.name_length,
    sm.excellent_count,
    sm.clean_comment,
    su.s_suppkey,
    su.s_name,
    su.formatted_address,
    su.part_count
FROM StringMetrics sm
JOIN SupplierMetrics su ON sm.name_length = su.part_count
ORDER BY sm.name_length DESC, su.part_count ASC
LIMIT 100;
