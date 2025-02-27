
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN ph.PostHistoryTypeId IS NOT NULL THEN 'Edited'
            ELSE 'Original'
        END AS PostStatus
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = p.Id
        )
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - 365 
      AND p.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        TRIM('<>' FROM value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(Tags, '>') 
    GROUP BY 
        TRIM('<>' FROM value)
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.PostStatus,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, '>'))
WHERE 
    tt.Rank <= 10 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
