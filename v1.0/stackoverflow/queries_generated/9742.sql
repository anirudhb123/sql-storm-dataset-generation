WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.UpVotes > p.DownVotes THEN 1 ELSE 0 END) AS TotalPopularPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges 
    GROUP BY 
        UserId
),
CombinedStats AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalPopularPosts,
        COALESCE(bc.BadgeCount, 0) AS TotalBadges
    FROM 
        UserStats us
    JOIN 
        Users u ON us.UserId = u.Id
    LEFT JOIN 
        BadgeCounts bc ON u.Id = bc.UserId
)
SELECT 
    *,
    (TotalPosts + TotalBadges * 2) AS EngagementScore
FROM 
    CombinedStats
WHERE 
    TotalPosts > 10
ORDER BY 
    EngagementScore DESC
LIMIT 20;
