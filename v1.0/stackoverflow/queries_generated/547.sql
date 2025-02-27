WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS ClosedPosts,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END), 0) AS DeletedPosts
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    WHERE P.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
FinalStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.CreationDate,
        US.LastAccessDate,
        US.UpVotes,
        US.DownVotes,
        P.Title AS PostTitle,
        P.ViewCount,
        P.Score,
        P.CommentCount,
        P.RelatedPostsCount,
        P.PostRank
    FROM UserStats US
    LEFT JOIN PostMetrics P ON US.UserId = P.PostId
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    CreationDate,
    LastAccessDate,
    UpVotes,
    DownVotes,
    Title AS PostTitle,
    ViewCount,
    Score,
    CommentCount,
    RelatedPostsCount,
    PostRank
FROM FinalStats
WHERE Reputation > 1000 
AND CreationDate < CURRENT_DATE - INTERVAL '5 years'
ORDER BY Reputation DESC, UpVotes DESC
LIMIT 10;

UNION ALL

SELECT 
    U.Id,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.LastAccessDate,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    NULL AS PostTitle,
    NULL AS ViewCount,
    NULL AS Score,
    NULL AS CommentCount,
    NULL AS RelatedPostsCount,
    NULL AS PostRank
FROM Users U
LEFT JOIN Votes V ON U.Id = V.UserId
WHERE U.Reputation < 100
GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
ORDER BY U.Reputation
LIMIT 5;
