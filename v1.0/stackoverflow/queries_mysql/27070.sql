
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(NULLIF(p.Score, 0), p.ViewCount / 10) AS EngagementScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COALESCE(NULLIF(p.Score, 0), p.ViewCount / 10) DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerDisplayName,
        r.CreationDate,
        r.LastActivityDate,
        r.EngagementScore,
        GROUP_CONCAT(t.TagName) AS Tags,
        r.PostRank
    FROM 
        RankedPosts r
    JOIN 
        Posts p ON r.PostId = p.Id
    JOIN 
        PopularTags t ON FIND_IN_SET(t.TagName, p.Tags) > 0
    GROUP BY 
        r.PostId, r.Title, r.OwnerDisplayName, r.CreationDate, r.LastActivityDate, r.EngagementScore, r.PostRank
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.EngagementScore,
    ps.Tags,
    CASE 
        WHEN ps.PostRank <= 5 THEN 'Top 5'
        WHEN ps.PostRank BETWEEN 6 AND 15 THEN 'Top 10-15'
        ELSE 'Others'
    END AS RankCategory
FROM 
    PostStatistics ps
WHERE 
    ps.PostRank <= 15
ORDER BY 
    ps.EngagementScore DESC, ps.CreationDate DESC;
