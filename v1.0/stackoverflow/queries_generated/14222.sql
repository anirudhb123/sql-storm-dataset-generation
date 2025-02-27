-- Performance Benchmarking Query
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(vt.VoteCount) AS TotalVotes,
        SUM(b.Id IS NOT NULL) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vt ON vt.PostId = p.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        SUM(Score) AS TotalScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalVotes,
    ua.TotalBadges,
    ps.PostType,
    ps.PostCount,
    ps.AvgViewCount,
    ps.TotalScore
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.TotalPosts > 0
ORDER BY 
    ua.TotalPosts DESC, ps.PostType;
