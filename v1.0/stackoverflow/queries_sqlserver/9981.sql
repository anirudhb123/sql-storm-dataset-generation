
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.Score > 0 
    AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
PopularTags AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS Popularity
    FROM Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, ',') 
    WHERE p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY value
    ORDER BY COUNT(*) DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    pt.Tag,
    pt.Popularity
FROM RankedPosts rp
JOIN PopularTags pt ON pt.Tag IN (SELECT value FROM STRING_SPLIT(rp.Title, ' '))
WHERE rp.Rank <= 5
ORDER BY rp.ViewCount DESC, rp.Score DESC;
