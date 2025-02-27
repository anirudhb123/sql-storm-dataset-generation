
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalViews,
    TotalScore,
    TotalComments,
    TotalVotes,
    (TotalViews + TotalScore + TotalComments + TotalVotes) AS EngagementScore
FROM 
    UserEngagement
ORDER BY 
    EngagementScore DESC;
