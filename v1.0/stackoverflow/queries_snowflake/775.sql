
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
    LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS TagsAssociated
FROM UserPostInfo uri 
JOIN UserReputation ur ON uri.UserId = ur.UserId
LEFT JOIN Posts p ON uri.UserId = p.OwnerUserId
LEFT JOIN LATERAL (
    SELECT 
        TRIM(SPLIT_PART(value, ',', index)) AS TagName
    FROM (
        SELECT 
            value, 
            ROW_NUMBER() OVER (PARTITION BY value ORDER BY value) AS index
        FROM (
            SELECT 
                p.Tags AS value
            FROM Posts p
        ) AS tag_values
        WHERE p.Tags IS NOT NULL
    )
) AS t ON TRUE
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
