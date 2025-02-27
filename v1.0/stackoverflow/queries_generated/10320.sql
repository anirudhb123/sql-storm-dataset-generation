-- Performance benchmarking query to analyze post statistics and user contributions
WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate))/3600) AS AvgPostAgeHours
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAwarded
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.DisplayName
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.PositivePosts,
    ps.NegativePosts,
    ps.AvgPostAgeHours,
    us.DisplayName,
    us.PostsCreated,
    us.TotalBadges,
    us.TotalBountyAwarded
FROM 
    PostStats ps
CROSS JOIN 
    UserStats us
ORDER BY 
    ps.TotalPosts DESC, us.PostsCreated DESC;
