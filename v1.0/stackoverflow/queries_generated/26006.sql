WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= '2023-01-01'  -- Posts created in 2023
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName  -- Split the tags into individual items
    FROM 
        RankedPosts
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS TagUsage
    FROM 
        PopularTags
    GROUP BY 
        TagName
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
CombinedStats AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.TotalPosts,
        up.PositiveScorePosts,
        up.PopularPosts,
        tc.TagName,
        tc.TagUsage
    FROM 
        UserPostStats up
    LEFT JOIN 
        TagCounts tc ON true  -- Cross join to associate users with all tags
)
SELECT 
    cs.DisplayName AS UserName,
    cs.TotalPosts,
    cs.PositiveScorePosts,
    cs.PopularPosts,
    cs.TagName,
    cs.TagUsage
FROM 
    CombinedStats cs
WHERE 
    cs.TotalPosts > 5  -- Only users with more than 5 posts
ORDER BY 
    cs.TagUsage DESC, cs.TotalPosts DESC;
