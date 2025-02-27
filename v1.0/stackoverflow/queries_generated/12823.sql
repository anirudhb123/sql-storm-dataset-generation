-- Performance Benchmarking Query
WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.DisplayName AS UserName,
        COUNT(p.Id) AS PostsCreated,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    pc.PostType,
    pc.TotalPosts,
    pc.PositiveScorePosts,
    pc.HighViewCountPosts,
    pc.AvgScore,
    pc.AvgViewCount,
    us.UserName,
    us.PostsCreated,
    us.TotalViews,
    us.TotalUpVotes,
    us.AvgScore
FROM 
    PostCounts pc
JOIN 
    UserStats us ON us.PostsCreated > 0
ORDER BY 
    pc.TotalPosts DESC, us.TotalViews DESC
LIMIT 100;
