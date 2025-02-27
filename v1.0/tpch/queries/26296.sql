WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_comment,
        CONCAT(s.s_name, ' [', p.p_name, ']') AS SupplierProduct,
        UPPER(p.p_brand) AS UpperBrand,
        LOWER(p.p_comment) AS LowerComment,
        LENGTH(p.p_comment) AS CommentLength,
        REPLACE(p.p_comment, 'special', 'premium') AS UpdatedComment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size BETWEEN 10 AND 50
    AND 
        p.p_retailprice > 100.00
),
AggregatedResults AS (
    SELECT 
        CONCAT(UPPER(p.p_brand), ' - ', p.p_type) AS BrandType,
        COUNT(*) AS TotalParts,
        AVG(CommentLength) AS AvgCommentLength,
        STRING_AGG(DISTINCT SupplierProduct, '; ') AS SupplierList,
        MAX(UpdatedComment) AS LongestUpdatedComment
    FROM 
        StringProcessing p
    GROUP BY 
        BrandType
)
SELECT 
    BrandType,
    TotalParts,
    AvgCommentLength,
    SupplierList,
    LongestUpdatedComment
FROM 
    AggregatedResults
ORDER BY 
    TotalParts DESC, AvgCommentLength DESC;
