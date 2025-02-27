WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        REGEXP_REPLACE(p.p_comment, '[^A-Za-z0-9]', '') AS cleaned_comment
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_comment,
        LENGTH(s.s_comment) AS comment_length,
        REGEXP_REPLACE(s.s_comment, '[^A-Za-z0-9]', '') AS cleaned_comment
    FROM 
        supplier s
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_comment,
        LENGTH(c.c_comment) AS comment_length,
        REGEXP_REPLACE(c.c_comment, '[^A-Za-z0-9]', '') AS cleaned_comment
    FROM 
        customer c
),
CombinedDetails AS (
    SELECT 
        'Part' AS entity_type,
        p.* 
    FROM 
        PartDetails p
    UNION ALL
    SELECT 
        'Supplier' AS entity_type,
        s.* 
    FROM 
        SupplierDetails s
    UNION ALL
    SELECT 
        'Customer' AS entity_type,
        c.* 
    FROM 
        CustomerDetails c
)
SELECT 
    entity_type,
    COUNT(*) AS total_records,
    AVG(comment_length) AS avg_comment_length,
    SUM(LENGTH(cleaned_comment)) AS total_cleaned_length
FROM 
    CombinedDetails
GROUP BY 
    entity_type
ORDER BY 
    entity_type;
