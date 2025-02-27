WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 -- Filter to users with high reputation
    GROUP BY 
        u.Id
),
TagPostCounts AS (
    SELECT 
        REGEXP_SPLIT_TO_TABLE(p.Tags, '><') AS TagName, 
        COUNT(p.Id) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TotalPosts,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        TagPostCounts
    WHERE 
        TotalPosts > 10 -- Only consider tags with more than 10 posts
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.TotalScore,
    up.AverageViewCount,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate,
    tt.TagName,
    tt.TotalPosts AS TagPostCount
FROM 
    UserStats up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.RowNum = 1
JOIN 
    TopTags tt ON tt.Rank <= 5 -- Top 5 tags
ORDER BY 
    up.TotalScore DESC, 
    up.TotalPosts DESC;
