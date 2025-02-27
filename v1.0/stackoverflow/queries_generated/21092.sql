WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 -- BountyStart
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS RankByViews
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.AcceptedAnswerId IS NOT NULL
),
CloseReasonSummary AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10 -- Closed
    GROUP BY PH.PostId, PH.Comment
),
UserPostDetails AS (
    SELECT 
        A.UserId,
        A.DisplayName,
        COUNT(DISTINCT A.PostId) AS AnswerCount,
        COALESCE(CR.CloseCount, 0) AS CloseCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScoreCount
    FROM Users A
    LEFT JOIN Posts P ON A.Id = P.OwnerUserId AND P.PostTypeId = 2 -- Answers
    LEFT JOIN CloseReasonSummary CR ON P.Id = CR.PostId
    GROUP BY A.UserId, A.DisplayName, CR.CloseCount
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(A.AnswerCount, 0) AS TotalAnswers,
    COALESCE(A.CloseCount, 0) AS TotalClosures,
    A.TotalViews,
    A.PositiveScoreCount,
    PA.RankByViews
FROM UserActivity U
LEFT JOIN UserPostDetails A ON U.UserId = A.UserId
LEFT JOIN PostStatistics PA ON A.AnswerCount > 0 AND A.TotalViews > 100
ORDER BY U.Reputation DESC, A.TotalAnswers DESC, PA.RankByViews ASC NULLS LAST;
