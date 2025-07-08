
WITH UserReputationTiers AS (
    SELECT 
        CASE 
            WHEN Reputation < 100 THEN 'Novice'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            WHEN Reputation > 1000 THEN 'Expert'
        END AS ReputationTier,
        COUNT(DISTINCT Id) AS UserCount
    FROM Users
    GROUP BY 
        CASE 
            WHEN Reputation < 100 THEN 'Novice'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            WHEN Reputation > 1000 THEN 'Expert'
        END
),
PostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts
    GROUP BY OwnerUserId
),
CommentCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS CommentCount
    FROM Comments
    GROUP BY UserId
)
SELECT 
    urt.ReputationTier,
    urt.UserCount,
    COALESCE(SUM(pc.PostCount), 0) AS TotalPostCount,
    COALESCE(SUM(pc.QuestionCount), 0) AS TotalQuestionCount,
    COALESCE(SUM(pc.AnswerCount), 0) AS TotalAnswerCount,
    COALESCE(SUM(cc.CommentCount), 0) AS TotalCommentCount
FROM UserReputationTiers urt
LEFT JOIN PostCounts pc ON pc.OwnerUserId IN (
    SELECT Id FROM Users WHERE Reputation < 100 AND 'Novice' = urt.ReputationTier
    UNION ALL
    SELECT Id FROM Users WHERE Reputation BETWEEN 100 AND 1000 AND 'Intermediate' = urt.ReputationTier
    UNION ALL
    SELECT Id FROM Users WHERE Reputation > 1000 AND 'Expert' = urt.ReputationTier
)
LEFT JOIN CommentCounts cc ON cc.UserId IN (
    SELECT Id FROM Users WHERE Reputation < 100 AND 'Novice' = urt.ReputationTier
    UNION ALL
    SELECT Id FROM Users WHERE Reputation BETWEEN 100 AND 1000 AND 'Intermediate' = urt.ReputationTier
    UNION ALL
    SELECT Id FROM Users WHERE Reputation > 1000 AND 'Expert' = urt.ReputationTier
)
GROUP BY urt.ReputationTier, urt.UserCount
ORDER BY urt.ReputationTier;
