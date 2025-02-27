WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUBSTRING(p.p_name FROM 1 FOR 10) AS short_name,
        CHAR_LENGTH(p.p_name) AS name_length,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY CHAR_LENGTH(p.p_name) DESC) AS rank_by_length
    FROM 
        part p
),
SuppliersWithComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT('Supplier: ', s.s_name, ' - Address: ', s.s_address) AS detailed_address,
        CHAR_LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
)
SELECT 
    rp.short_name,
    rp.name_length,
    swc.detailed_address,
    swc.comment_length
FROM 
    RankedParts rp
JOIN 
    SuppliersWithComments swc ON rp.p_partkey % 10 = swc.s_suppkey % 10
WHERE 
    rp.rank_by_length <= 5
ORDER BY 
    rp.name_length DESC, 
    swc.comment_length ASC
LIMIT 100;
