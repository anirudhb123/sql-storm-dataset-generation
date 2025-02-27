
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
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '>', -1) AS Tag,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= n.n - 1
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 MONTH
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
    PopularTags pt ON FIND_IN_SET(pt.Tag, REPLACE(p.Tags, '>', ',')) > 0
WHERE 
    ups.NumberOfPosts > 0
GROUP BY 
    ups.DisplayName, ups.NumberOfPosts, ups.TotalViews, ups.TotalScore, lp.Title, lp.CreationDate
ORDER BY 
    ups.TotalScore DESC
LIMIT 10;
