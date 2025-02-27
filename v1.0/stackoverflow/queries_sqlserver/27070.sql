
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
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),
PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, ',') AS Tag
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostStatistics AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerDisplayName,
        r.CreationDate,
        r.LastActivityDate,
        r.EngagementScore,
        STRING_AGG(t.TagName, ',') AS Tags,
        r.PostRank
    FROM 
        RankedPosts r
    JOIN 
        Posts p ON r.PostId = p.Id
    JOIN 
        PopularTags t ON t.TagName IN (SELECT value FROM STRING_SPLIT(p.Tags, ','))
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
