WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY U.Id
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalComments,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Ranking
    FROM UserActivity
)

SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalComments,
    TU.TotalBounty,
    (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = TU.UserId AND P.AcceptedAnswerId IS NOT NULL) AS AcceptedAnswers,
    COALESCE((SELECT MAX(H.CreationDate) FROM PostHistory H WHERE H.UserId = TU.UserId AND H.PostHistoryTypeId IN (10, 11)), 'Never') AS LastClosedPost,
    CASE 
        WHEN TU.TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus
FROM TopUsers TU
WHERE TU.Ranking <= 10
ORDER BY TU.TotalPosts DESC;
