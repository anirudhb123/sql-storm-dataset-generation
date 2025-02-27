-- Performance Benchmarking Query

WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.QuestionCount,
    up.AnswerCount,
    up.TotalScore,
    up.AverageViews,
    up.LastPostDate,
    DATEDIFF(NOW(), up.LastPostDate) AS DaysSinceLastPost
FROM UserPosts up
WHERE up.PostCount > 0
ORDER BY up.TotalScore DESC, up.PostCount DESC
LIMIT 100;
