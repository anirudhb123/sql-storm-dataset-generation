
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
        p.CreationDate >= DATEADD(year, -1, '2024-10-01'::DATE)
      AND p.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        TRIM(BOTH '<>' FROM value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts,
        LATERAL FLATTEN(input => SPLIT(RankedPosts.Tags, '>')) AS value
    GROUP BY 
        TagName
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
    TopTags tt ON tt.TagName IN (SELECT TRIM(BOTH '<>' FROM value) FROM LATERAL FLATTEN(input => SPLIT(rp.Tags, '>')) AS value)
WHERE 
    tt.Rank <= 10 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
