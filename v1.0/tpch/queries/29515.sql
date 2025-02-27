WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_comment,
        CONCAT('Brand: ', p.p_brand, ', Name: ', p.p_name) AS full_description,
        LENGTH(p.p_name) AS name_length,
        REPLACE(LOWER(p.p_comment), 'old', 'new') AS modified_comment
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
AggregatedData AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT sp.p_partkey) AS unique_parts,
        AVG(sp.name_length) AS avg_name_length,
        STRING_AGG(sp.modified_comment, ', ') AS all_modified_comments
    FROM 
        StringProcessing sp
    JOIN 
        partsupp ps ON sp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    ad.s_name,
    ad.unique_parts,
    ad.avg_name_length,
    SUBSTRING(ad.all_modified_comments, 1, 200) AS truncated_comments
FROM 
    AggregatedData ad
ORDER BY 
    ad.unique_parts DESC, ad.avg_name_length;
