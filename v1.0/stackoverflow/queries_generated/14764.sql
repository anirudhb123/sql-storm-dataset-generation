-- Performance Benchmarking Query
WITH PostAggregates AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.CreationDate) AS AvgCreationDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation AS Reputation
    FROM 
        Users u
)
SELECT 
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalScore,
    ua.TotalViews,
    ur.Reputation,
    ur.Reputation * ua.TotalPosts AS UserValue
FROM 
    PostAggregates ua
JOIN 
    Users u ON u.Id = ua.OwnerUserId
JOIN 
    UserReputation ur ON ur.UserId = u.Id
ORDER BY 
    UserValue DESC
LIMIT 100;
