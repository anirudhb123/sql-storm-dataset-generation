
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COALESCE(ph.Comment, 'No Comments') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        p.CreationDate >= '2023-01-01'
),
TagStatistics AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        LATERAL SPLIT_TO_TABLE(Tags, '><') AS value
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(value)
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS PopularityRank
    FROM 
        TagStatistics
    WHERE 
        TagCount > 10  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.LastEditComment,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags LIKE '%' || tt.TagName || '%'
WHERE 
    rp.CommentRank = 1
ORDER BY 
    tt.TagCount DESC,
    rp.CreationDate DESC
LIMIT 50;
