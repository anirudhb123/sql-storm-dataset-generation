WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(P.CreationDate) AS LastPostDate,
        SUM(COALESCE(CM.Score, 0)) AS TotalCommentScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    GROUP BY U.Id
),
CloseReasonAggregates AS (
    SELECT 
        PH.UserId,
        PH.PostHistoryTypeId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT CR.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CR ON PH.Comment::int = CR.Id
    WHERE PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY PH.UserId, PH.PostHistoryTypeId
),
PostLinkStats AS (
    SELECT 
        PL.PostId,
        COUNT(*) AS LinkCount,
        MAX(PL.CreationDate) AS LastLinkDate
    FROM PostLinks PL
    GROUP BY PL.PostId
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.LastPostDate,
    COALESCE(CRA.CloseReasonCount, 0) AS CloseReasonCount,
    COALESCE(CRA.CloseReasons, 'None') AS CloseReasons,
    COALESCE(PLS.LinkCount, 0) AS TotalLinks,
    PLS.LastLinkDate,
    EXTRACT(YEAR FROM AGE(UA.LastPostDate)) AS YearsSinceLastPost,
    CASE 
        WHEN UA.Reputation > 2000 THEN 'High Reputation'
        WHEN UA.Reputation > 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM UserActivity UA
LEFT JOIN CloseReasonAggregates CRA ON UA.UserId = CRA.UserId
LEFT JOIN PostLinkStats PLS ON UA.PostCount > 0 AND (UA.PostCount % 3 = 0)  -- Assume a user has Posts
WHERE UA.Reputation IS NOT NULL
ORDER BY UA.Reputation DESC, UA.PostCount DESC
LIMIT 100
OPTION (RECOMPILE); -- Hypothetical option to encourage optimization

-- Additional complex filtering excluding users who have closed questions without providing feedback
AND NOT EXISTS (
    SELECT 1
    FROM PostHistory PH
    WHERE PH.UserId = UA.UserId AND PH.PostHistoryTypeId = 10 AND PH.Comment IS NOT NULL
)
AND UA.LastPostDate BETWEEN '2022-01-01' AND CURRENT_TIMESTAMP
OR UA.TotalCommentScore > 100;

-- Checking for specific bizarre scenarios, such as users with a discrepancy between their promised contribution (by badges) and actual post count
JOIN (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(B.Class) AS TotalBadgeClass
    FROM Badges B
    GROUP BY B.UserId
) BD ON UA.UserId = BD.UserId
WHERE BD.BadgeCount >= 5 AND BD.TotalBadgeClass > 7;

-- Finally, conclude with various NULL checks and logic
HAVING COUNT(DISTINCT UA.UserId) IS NOT NULL AND SUM(UA.Reputation) IS NOT NULL;
