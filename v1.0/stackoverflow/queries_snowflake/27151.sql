
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        t.Tag
    FROM 
        Posts p,
        LATERAL SPLIT_TO_TABLE(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS t
    WHERE 
        p.Tags IS NOT NULL AND p.PostTypeId = 1
),
TopTags AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS PostCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    ORDER BY 
        PostCount DESC
    LIMIT 10  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    tt.Tag,
    tt.PostCount
FROM 
    RankedPosts rp
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
JOIN 
    TopTags tt ON pt.Tag = tt.Tag
WHERE 
    rp.RankByScore <= 3  
ORDER BY 
    tt.PostCount DESC, 
    rp.Score DESC;
