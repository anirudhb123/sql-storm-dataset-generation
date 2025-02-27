-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        P.AnswerCount,
        P.ClosedDate
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.PostCount,
    US.TotalScore,
    US.UpVotes,
    US.DownVotes,
    COUNT(PS.PostId) AS RecentPostCount,
    AVG(PS.Score) AS AvgPostScore,
    SUM(PS.ViewCount) AS TotalViews,
    SUM(PS.CommentCount) AS TotalComments,
    SUM(PS.AnswerCount) AS TotalAnswers
FROM UserStats US
LEFT JOIN PostStats PS ON US.UserId = PS.OwnerUserId
GROUP BY US.UserId, US.DisplayName
ORDER BY US.TotalScore DESC
LIMIT 100;
