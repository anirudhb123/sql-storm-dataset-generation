WITH RecursiveTopTags AS (
    -- CTE to recursively gather tags and their post count
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = Posts.Id
    GROUP BY 
        Tags.TagName

    UNION ALL

    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) + rt.PostCount
    FROM 
        Tags
    INNER JOIN 
        Posts ON Tags.Id = Posts.Id
    INNER JOIN 
        RecursiveTopTags rt ON Tags.Id = rt.TagName -- note: adjust join logic based on actual structure
    GROUP BY 
        Tags.TagName
), AggregatedPostMetrics AS (
    -- CTE to aggregate metrics on posts
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount,
        AVG(p.Score) AS AverageScore,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (9, 10) -- BountyClose, Deletion
    GROUP BY 
        p.OwnerUserId
), UserReputation AS (
    -- CTE to associate users with their reputation score and post metrics
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ap.TotalPosts,
        ap.TotalBountyAmount,
        ap.AverageScore,
        ap.ClosedPostCount
    FROM 
        Users u
    LEFT JOIN 
        AggregatedPostMetrics ap ON u.Id = ap.OwnerUserId
), TopUsers AS (
    -- CTE to rank users based on reputation and post metrics
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalBountyAmount,
        AverageScore,
        ClosedPostCount,
        RANK() OVER (ORDER BY Reputation DESC, TotalPosts DESC) AS Rank
    FROM 
        UserReputation
)
SELECT 
    u.DisplayName,
    u.Location,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalBountyAmount,
    tu.AverageScore,
    tu.ClosedPostCount,
    tt.TagName AS PopularTag,
    tt.PostCount
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
LEFT JOIN 
    RecursiveTopTags tt ON tt.PostCount > 5 -- Only consider tags with more than 5 posts
WHERE 
    tu.Reputation > 1000 -- Filter for users with a reputation greater than 1000
ORDER BY 
    tu.Rank, tu.TotalPosts DESC;
