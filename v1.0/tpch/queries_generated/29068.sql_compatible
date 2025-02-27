
WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_brand,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        STRING_AGG(DISTINCT CONCAT('Available in: ', s.s_name), ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_type, p.p_brand, p.p_comment
)

SELECT 
    CONCAT('Part:', p.p_partkey, ' | Name:', p.p_name, ' | Manufacturer:', p.p_mfgr, 
           ' | Type:', p.p_type, ' | Brand:', p.p_brand, 
           ' | Comment:', p.short_comment, 
           ' | Suppliers:', p.supplier_names) AS part_info
FROM 
    PartDetails p
WHERE 
    LENGTH(p.p_name) > 10
ORDER BY 
    p.p_partkey
LIMIT 100;
