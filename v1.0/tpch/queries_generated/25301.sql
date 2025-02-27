WITH String_Processing AS (
    SELECT 
        p.p_name,
        l.l_shipmode,
        CONCAT('Supplier:', s.s_name, ' | Part:', p.p_name, ' | Nation:', n.n_name) AS combined_info,
        LENGTH(CONCAT('Supplier:', s.s_name, ' | Part:', p.p_name, ' | Nation:', n.n_name)) AS info_length,
        UPPER(SUBSTRING(p.p_comment, 1, 10)) AS short_comment,
        REPLACE(s.s_comment, 'Quality', 'Superior') AS modified_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        n.n_name LIKE 'A%' AND l.l_shipmode IN ('TRUCK', 'SHIP')
)
SELECT 
    AVG(info_length) AS avg_info_length,
    COUNT(DISTINCT combined_info) AS unique_combinations,
    COUNT(*) AS total_count,
    STRING_AGG(DISTINCT short_comment, ', ') AS short_comments_aggregated,
    STRING_AGG(DISTINCT modified_comment, '; ') AS modified_comments_aggregated
FROM 
    String_Processing;
