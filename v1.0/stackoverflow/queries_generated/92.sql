WITH UserSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(U.Reputation) OVER() AS AverageReputation,
        MAX(U.Reputation) AS MaxReputation
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId AND V.VoteTypeId = 9
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id
),
ClosedPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedPostCount
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10 
    GROUP BY P.OwnerUserId
),
QuestionWithHighestVote AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.Score,
        RANK() OVER (ORDER BY P.Score DESC) AS Rank
    FROM Posts P
    WHERE P.PostTypeId = 1
)
SELECT 
    U.DisplayName,
    US.TotalPosts,
    US.TotalComments,
    COALESCE(CP.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(QuestionHighest.Title, 'No Questions') AS TopQuestion,
    US.MaxReputation,
    US.AverageReputation,
    (US.TotalBounties - COALESCE(SUM(B.BountyAmount), 0) FILTER (WHERE B.UserId = U.Id) OVER()) AS RemainingBountyCredits
FROM UserSummary US
LEFT JOIN ClosedPosts CP ON US.UserId = CP.OwnerUserId
LEFT JOIN QuestionWithHighestVote QuestionHighest ON US.UserId = (
    SELECT P.OwnerUserId
    FROM Posts P
    WHERE P.Id = QuestionHighest.QuestionId
)
LEFT JOIN Votes B ON US.UserId = B.UserId AND B.VoteTypeId = 8 
WHERE US.TotalPosts > 0
ORDER BY US.MaxReputation DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
