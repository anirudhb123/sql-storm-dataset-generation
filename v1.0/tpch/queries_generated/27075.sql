WITH String_Processing AS (
    SELECT 
        SUBSTRING(p_name, 1, 10) AS short_name,
        UPPER(p_mfgr) AS uppercase_mfgr,
        LOWER(p_brand) AS lowercase_brand,
        CONCAT(p_type, ' - ', p_container) AS combined_type_container,
        LENGTH(p_comment) AS comment_length,
        REPLACE(p_comment, 'special', 'standard') AS modified_comment
    FROM 
        part
), Aggregated AS (
    SELECT 
        COUNT(*) AS total_parts,
        MIN(comment_length) AS min_comment_length,
        MAX(comment_length) AS max_comment_length,
        AVG(comment_length) AS avg_comment_length,
        STRING_AGG(short_name, ', ') AS aggregated_short_names,
        STRING_AGG(uppercase_mfgr, ', ') AS aggregated_uppercase_mfgrs,
        STRING_AGG(lowercase_brand, ', ') AS aggregated_lowercase_brands,
        STRING_AGG(combined_type_container, '; ') AS aggregated_combined_type_container,
        STRING_AGG(modified_comment, '; ') AS aggregated_modified_comments
    FROM 
        String_Processing
)
SELECT 
    a.total_parts,
    a.min_comment_length,
    a.max_comment_length,
    a.avg_comment_length,
    a.aggregated_short_names,
    a.aggregated_uppercase_mfgrs,
    a.aggregated_lowercase_brands,
    a.aggregated_combined_type_container,
    a.aggregated_modified_comments,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name
FROM 
    Aggregated a
JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps_suppkey FROM partsupp)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, n.n_name, s.s_name, a.total_parts, a.min_comment_length, a.max_comment_length, a.avg_comment_length, a.aggregated_short_names, a.aggregated_uppercase_mfgrs, a.aggregated_lowercase_brands, a.aggregated_combined_type_container, a.aggregated_modified_comments
ORDER BY 
    a.avg_comment_length DESC;
