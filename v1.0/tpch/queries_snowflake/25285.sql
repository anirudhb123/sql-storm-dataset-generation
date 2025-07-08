
WITH String_Utils AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_comment,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Price: $', p.p_retailprice) AS detailed_info,
        LENGTH(p.p_comment) AS comment_length,
        REVERSE(p.p_name) AS reversed_part_name,
        UPPER(p.p_mfgr) AS manufacturer_upper
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
Processed_Strings AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.manufacturer_upper,
        LISTAGG(detailed_info, '; ') WITHIN GROUP (ORDER BY detailed_info) AS brief_details,
        SUM(comment_length) AS total_comment_length
    FROM 
        String_Utils p
    GROUP BY 
        p.p_partkey, p.p_name, p.manufacturer_upper
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.manufacturer_upper,
    p.brief_details,
    p.total_comment_length,
    COUNT(*) OVER() AS total_records
FROM 
    Processed_Strings p
WHERE 
    total_comment_length > 50
ORDER BY 
    total_comment_length DESC;
