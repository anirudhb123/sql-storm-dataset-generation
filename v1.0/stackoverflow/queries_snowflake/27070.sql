
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
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p,
        LATERAL FLATTEN(input => SPLIT(p.Tags, ',')) AS value
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
        ARRAY_AGG(t.TagName) AS Tags,
        r.PostRank
    FROM 
        RankedPosts r
    JOIN 
        Posts p ON r.PostId = p.Id
    JOIN 
        PopularTags t ON t.TagName IN (SELECT TRIM(value) FROM LATERAL FLATTEN(input => SPLIT(p.Tags, ',')) AS value)
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
