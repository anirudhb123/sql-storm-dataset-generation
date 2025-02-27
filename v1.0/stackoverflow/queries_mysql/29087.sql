
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
        p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
      AND p.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
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
    TopTags tt ON FIND_IN_SET(tt.TagName, rp.Tags) > 0
WHERE 
    tt.Rank <= 10 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
