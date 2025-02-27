
WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Type: ', p.p_type) AS description,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_mfgr) AS manufacturer_upper,
        LOWER(p.p_comment) AS comment_lower,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS cleaned_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    r.r_name,
    STRING_AGG(sp.description, '; ') AS all_descriptions,
    AVG(sp.name_length) AS avg_name_length,
    COUNT(DISTINCT sp.manufacturer_upper) AS unique_manufacturers,
    COUNT(DISTINCT sp.cleaned_comment) AS unique_comments
FROM 
    StringProcessing sp
JOIN 
    supplier s ON sp.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
