
WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        LENGTH(p.p_name) AS name_length,
        SUBSTR(p.p_comment, 1, 10) AS comment_preview,
        REPLACE(p.p_comment, 'Quality', 'Excellence') AS modified_comment,
        CONCAT('Part: ', p.p_name, ' - Comment: ', p.p_comment) AS concatenated_info
    FROM part p
),
AggregatedInfo AS (
    SELECT 
        p.p_partkey,
        LISTAGG(sp.upper_name, ', ') WITHIN GROUP (ORDER BY sp.upper_name) AS all_upper_names,
        COUNT(sp.name_length) AS total_name_lengths,
        SUM(sp.name_length) AS cumulative_name_length,
        LISTAGG(sp.comment_preview, ', ') WITHIN GROUP (ORDER BY sp.comment_preview) AS all_comment_previews,
        LISTAGG(sp.modified_comment, ', ') WITHIN GROUP (ORDER BY sp.modified_comment) AS all_modified_comments,
        LISTAGG(sp.concatenated_info, '; ') WITHIN GROUP (ORDER BY sp.concatenated_info) AS all_concatenated_info
    FROM StringProcessing sp
    JOIN part p ON sp.p_partkey = p.p_partkey
    GROUP BY p.p_partkey
)
SELECT 
    a.p_partkey,
    a.all_upper_names,
    a.total_name_lengths,
    a.cumulative_name_length,
    a.all_comment_previews,
    a.all_modified_comments,
    a.all_concatenated_info
FROM AggregatedInfo a
WHERE a.total_name_lengths > 100
ORDER BY a.cumulative_name_length DESC;
