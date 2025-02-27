
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.ProfileImageUrl,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostInfo AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.TotalScore, 0) AS TotalScore
    FROM Users u
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
)
SELECT 
    uri.UserId,
    uri.DisplayName,
    uri.TotalPosts,
    uri.TotalQuestions,
    uri.TotalAnswers,
    uri.TotalViews,
    uri.TotalScore,
    ur.Reputation,
    ur.ReputationRank,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsAssociated
FROM UserPostInfo uri 
JOIN UserReputation ur ON uri.UserId = ur.UserId
LEFT JOIN Posts p ON uri.UserId = p.OwnerUserId
LEFT JOIN (
    SELECT 
        p.OwnerUserId, 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
    FROM 
        Posts p
    INNER JOIN (SELECT a.N + b.N * 10 + 1 n FROM 
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a, 
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1 
) t ON uri.UserId = t.OwnerUserId
WHERE uri.TotalPosts > 0
GROUP BY 
    uri.UserId, 
    uri.DisplayName, 
    uri.TotalPosts, 
    uri.TotalQuestions, 
    uri.TotalAnswers, 
    uri.TotalViews, 
    uri.TotalScore, 
    ur.Reputation, 
    ur.ReputationRank
ORDER BY 
    ur.Reputation DESC, 
    uri.TotalPosts DESC
LIMIT 100;
