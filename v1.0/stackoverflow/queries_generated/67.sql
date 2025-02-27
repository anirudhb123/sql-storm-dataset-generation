WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 10000
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS PostUpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS PostDownVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        MIN(PH.CreationDate) AS FirstCloseDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId, PH.CreationDate
)
SELECT 
    UA.DisplayName,
    UA.UpVotes,
    UA.DownVotes,
    UA.TotalPosts,
    UA.TotalComments,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.PostRank,
    COALESCE(CP.FirstCloseDate, 'Not Closed') AS FirstCloseDate
FROM UserActivity UA
JOIN PostStatistics PS ON UA.UserId = PS.OwnerUserId
LEFT JOIN ClosedPosts CP ON PS.PostId = CP.PostId
WHERE PS.PostRank = 1
ORDER BY UA.UpVotes DESC, UA.TotalPosts DESC;
