WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
PartDetails AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.p_partkey,
        sp.p_name,
        sp.p_brand,
        sp.p_type,
        sp.p_size,
        sp.p_retailprice,
        sp.p_comment,
        sp.ps_availqty,
        sp.ps_supplycost,
        sp.ps_comment,
        CONCAT(sp.p_name, ' - ', sp.p_type) AS full_description,
        LENGTH(sp.p_comment) AS comment_length,
        REPLACE(sp.p_comment, 'old', 'new') AS modified_comment
    FROM 
        SupplierParts sp
)
SELECT 
    pd.s_suppkey,
    pd.s_name,
    COUNT(*) AS total_parts,
    AVG(pd.ps_supplycost) AS avg_supply_cost,
    SUM(pd.ps_availqty) AS total_available_quantity,
    MAX(pd.comment_length) AS max_comment_length,
    STRING_AGG(pd.full_description, ', ') AS part_descriptions,
    STRING_AGG(pd.modified_comment, '; ') AS updated_comments
FROM 
    PartDetails pd
GROUP BY 
    pd.s_suppkey, pd.s_name
ORDER BY 
    total_parts DESC;
