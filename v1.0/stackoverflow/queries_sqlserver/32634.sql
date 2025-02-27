
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
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS NumberOfPosts,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        value AS Tag,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '>') AS TagsTable
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -1, '2024-10-01 12:34:56')
    GROUP BY 
        TagsTable.value
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
    PopularTags pt ON pt.Tag = p.Tags
WHERE 
    ups.NumberOfPosts > 0
GROUP BY 
    ups.DisplayName, ups.NumberOfPosts, ups.TotalViews, ups.TotalScore, lp.Title, lp.CreationDate
ORDER BY 
    ups.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
