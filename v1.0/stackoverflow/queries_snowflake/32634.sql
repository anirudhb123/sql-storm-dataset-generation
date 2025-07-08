
WITH LatestPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS NumberOfPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p,
        LATERAL SPLIT_TO_TABLE(p.Tags, '>') AS value
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    ups.DisplayName,
    ups.NumberOfPosts,
    ups.TotalViews,
    ups.TotalScore,
    lp.Title AS LatestPostTitle,
    lp.CreationDate AS LatestPostDate,
    COUNT(pt.Tag) AS PopularTagCount
FROM 
    UserPostStats ups
JOIN 
    LatestPosts lp ON ups.UserId = lp.OwnerUserId
JOIN 
    Posts p ON lp.PostId = p.Id
LEFT JOIN 
    PopularTags pt ON pt.Tag = TRIM(value) 
    AND value IN (SELECT TRIM(value) FROM TABLE(SPLIT_TO_TABLE(p.Tags, '>')))
WHERE 
    ups.NumberOfPosts > 0
GROUP BY 
    ups.DisplayName, ups.NumberOfPosts, ups.TotalViews, ups.TotalScore, lp.Title, lp.CreationDate
ORDER BY 
    ups.TotalScore DESC
LIMIT 10;
