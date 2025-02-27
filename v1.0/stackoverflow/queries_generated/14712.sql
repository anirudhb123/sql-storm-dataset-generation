-- Performance Benchmarking Query

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(B.Id IS NOT NULL) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.OwnerUserId) AS UniqueUsers
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY PT.Name
),
RecentActivity AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        P.Title,
        U.DisplayName AS User,
        P.Score
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    JOIN Users U ON PH.UserId = U.Id
    WHERE PH.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
)

SELECT 
    UA.UserId,
    UA.Reputation,
    UA.PostCount,
    UA.CommentCount,
    UA.UpVotes,
    UA.DownVotes,
    UA.BadgeCount,
    PS.PostType,
    PS.TotalPosts,
    PS.AvgScore,
    PS.TotalViews,
    PS.UniqueUsers,
    R.PostId,
    R.CreationDate,
    R.Title,
    R.User,
    R.Score
FROM UserActivity UA
FULL OUTER JOIN PostStatistics PS ON UA.UserId IS NOT NULL OR PS.PostType IS NOT NULL
LEFT JOIN RecentActivity R ON R.PostId IS NOT NULL
ORDER BY UA.Reputation DESC, PS.TotalPosts DESC;
