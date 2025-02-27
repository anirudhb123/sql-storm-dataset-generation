WITH UserReputation AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(C) AS CommentCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        UReputation.Reputation,
        PS.QuestionCount,
        PS.TotalViews,
        PS.TotalScore
    FROM UserReputation UReputation
    JOIN PostStatistics PS ON UReputation.Id = PS.OwnerUserId
    WHERE UReputation.Reputation > 1000
    ORDER BY UReputation.Reputation DESC
    LIMIT 10
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.QuestionCount,
    T.TotalViews,
    COALESCE(T.TotalScore, 0) AS TotalScore,
    COALESCE(PH.CloseReason, 'No Close Reasons') AS MostRecentCloseReason
FROM TopUsers T
LEFT JOIN (
    SELECT 
        PH.UserId,
        STRING_AGG(CAST(CRT.Name AS VARCHAR), ', ') AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE PH.PostHistoryTypeId IN (10, 11)
    GROUP BY PH.UserId
) AS PH ON T.Id = PH.UserId
ORDER BY T.Reputation DESC;
