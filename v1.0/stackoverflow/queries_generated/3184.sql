WITH UserReputationChange AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        U.Reputation + COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 10 WHEN V.VoteTypeId = 3 THEN -5 END), 0) AS NewReputation
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
LatestPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 month'
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        PH.CreationDate AS CloseDate,
        C.Name AS CloseReason
    FROM PostHistory PH
    INNER JOIN Posts P ON PH.PostId = P.Id
    INNER JOIN CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE PH.PostHistoryTypeId = 10
)
SELECT 
    U.DisplayName,
    UReputation.NewReputation,
    COALESCE(LP.Title, 'No Posts') AS LatestPostTitle,
    LP.CreationDate AS LatestPostDate,
    COALESCE(CP.CloseDate, 'Not Closed') AS ClosureDate,
    CP.CloseReason AS ClosureReason,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = COALESCE(LP.PostId, -1)) AS CommentCount
FROM UserReputationChange UReputation
LEFT JOIN LatestPosts LP ON UReputation.UserId = LP.OwnerUserId AND LP.rn = 1
LEFT JOIN ClosedPosts CP ON LP.PostId = CP.PostId
WHERE UReputation.NewReputation > 1000
ORDER BY UReputation.NewReputation DESC
LIMIT 10;
