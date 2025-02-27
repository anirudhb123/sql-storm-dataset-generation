WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT(n.n_name, ' ', r.r_name) AS nation_region,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info,
        LENGTH(p.p_comment) AS comment_length,
        UPPER(SUBSTRING(s.s_name FROM 1 FOR 3)) AS supplier_prefix,
        TRIM(REPLACE(p.p_name, ' ', '_')) AS sanitized_part_name,
        REPLACE(p.p_comment, 'special', 'unique') AS modified_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        p.p_retailprice > 50.00
    ORDER BY 
        comment_length DESC
    LIMIT 100
)
SELECT 
    *,
    JSON_BUILD_OBJECT(
        'part_name', sanitized_part_name,
        'supplier_details', supplier_info,
        'nation_region', nation_region,
        'updated_comment', modified_comment
    ) AS json_output
FROM 
    StringProcessing;
