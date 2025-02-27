WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
QuestionStats AS (
    SELECT 
        P.Id AS QuestionId,
        P.OwnerUserId,
        P.LastActivityDate,
        COUNT(DISTINCT C.Id) AS TotalComments,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id
),
ClosedQuestions AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PT.Name AS CloseReason
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN CloseReasonTypes PT ON CAST(PH.Comment AS INT) = PT.Id
    WHERE PHT.Name = 'Post Closed'
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    COALESCE(US.TotalBounty, 0) AS TotalBounty,
    COUNT(DISTINCT QS.QuestionId) AS ClosedQuestionCount,
    MAX(CASE WHEN QS.LastActivityDate IS NOT NULL THEN QS.LastActivityDate ELSE '1970-01-01' END) AS LastActivity,
    STRING_AGG(DISTINCT CQ.CloseReason, ', ') AS CloseReasons
FROM UserStatistics US
LEFT JOIN QuestionStats QS ON US.UserId = QS.OwnerUserId
LEFT JOIN ClosedQuestions CQ ON QS.QuestionId = CQ.PostId
GROUP BY US.UserId, US.DisplayName, US.Reputation, US.TotalPosts, US.TotalQuestions, US.TotalAnswers
ORDER BY US.Reputation DESC, ClosedQuestionCount DESC
LIMIT 100;
