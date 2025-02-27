WITH StringAnalytics AS (
    SELECT 
        p.p_name AS part_name,
        LENGTH(p.p_name) AS name_length,
        LOWER(p.p_name) AS lower_name,
        UPPER(p.p_name) AS upper_name,
        REPLACE(p.p_comment, 'mistake', 'correction') AS corrected_comment,
        CONCAT(p.p_brand, ' - ', p.p_mfgr) AS brand_mfgr,
        SUBSTRING(p.p_comment, 1, 10) AS comment_preview,
        REGEXP_REPLACE(p.p_name, '[^a-zA-Z0-9]', '') AS sanitized_name
    FROM 
        part p
    WHERE 
        p_size > 10
),
AggregatedResults AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(n.n_nationkey) AS nation_count,
        AVG(sa.name_length) AS avg_name_length,
        SUM(CASE WHEN sa.name_length > 20 THEN 1 ELSE 0 END) AS long_names_count,
        STRING_AGG(DISTINCT sa.lower_name, ', ') AS all_lower_names,
        STRING_AGG(DISTINCT sa.upper_name, ', ') AS all_upper_names
    FROM 
        StringAnalytics sa
    JOIN 
        supplier s ON s.s_suppkey = sa.suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    ar.region_name,
    ar.nation_count,
    ar.avg_name_length,
    ar.long_names_count,
    ar.all_lower_names,
    ar.all_upper_names
FROM 
    AggregatedResults ar
ORDER BY 
    ar.region_name;
