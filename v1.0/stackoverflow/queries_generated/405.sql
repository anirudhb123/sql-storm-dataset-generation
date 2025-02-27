WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Reputation IS NULL THEN 1 ELSE 0 END) AS NullReputationPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        NullReputationPosts,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserPostStats
),
PostClosureReasons AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    GROUP BY p.Id
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.NullReputationPosts,
    pr.CloseReasons,
    CASE 
        WHEN ru.TotalAnswers > 0 THEN ROUND((ru.TotalQuestions::decimal / ru.TotalAnswers)::numeric, 2)
        ELSE NULL
    END AS QuestionToAnswerRatio
FROM RankedUsers ru
LEFT JOIN PostClosureReasons pr ON pr.PostId IN (
    SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ru.UserId AND p.PostTypeId = 1
)
WHERE ru.PostRank <= 10
ORDER BY ru.TotalPosts DESC;
