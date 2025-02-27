WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        LastAccessDate
    FROM 
        Users
    WHERE 
        Reputation > 1000 -- starting point for recursive CTE with reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.LastAccessDate
    FROM 
        Users u
    INNER JOIN 
        UserReputation ur ON u.Reputation = ur.Reputation + 500 -- Incrementing reputation by 500 for subsequent levels
    WHERE 
        u.Reputation <= 2000 -- limit the depth of recursion
),
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.Reputation,
        pm.TotalPosts,
        pm.TotalQuestions,
        pm.TotalAnswers,
        pm.TotalViews,
        pm.AverageScore,
        ub.TotalBadges,
        ub.BadgeNames
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostMetrics pm ON ur.Id = pm.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON ur.Id = ub.UserId
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.Reputation,
    COALESCE(f.TotalPosts, 0) AS TotalPosts,
    COALESCE(f.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(f.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(f.TotalViews, 0) AS TotalViews,
    COALESCE(f.AverageScore, 0) AS AverageScore,
    COALESCE(f.TotalBadges, 0) AS TotalBadges,
    COALESCE(f.BadgeNames, 'No Badges') AS BadgeNames
FROM 
    FinalMetrics f
ORDER BY 
    f.Reputation DESC
FETCH FIRST 100 ROWS ONLY; -- Limiting to top 100 users by reputation
