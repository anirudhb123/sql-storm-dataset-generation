WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
InactiveUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.LastAccessDate < NOW() - INTERVAL '1 year'
    GROUP BY U.Id
    HAVING COUNT(P.Id) = 0
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        COALESCE(V.VoteCount, 0) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.Id, V.VoteCount
),
HighScorePosts AS (
    SELECT 
        RP.PostId, 
        RP.Title, 
        RP.VoteCount, 
        RP.CommentCount,
        U.Id AS UserId,
        U.DisplayName AS UserName
    FROM RecentPosts RP
    JOIN Users U ON RP.PostId IN (
        SELECT P.Id 
        FROM Posts P 
        WHERE P.OwnerUserId = U.Id
    )
    WHERE RP.VoteCount >= 10
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    COALESCE(I.PostCount, 0) AS InactivePostCount,
    H.PostId,
    H.Title,
    H.VoteCount,
    H.CommentCount,
    R.Reputation as UserReputation,
    R.ReputationRank
FROM UserReputation R
JOIN InactiveUsers I ON I.UserId = R.UserId
LEFT JOIN HighScorePosts H ON H.UserId = U.UserId
WHERE R.Reputation >= 1000
ORDER BY R.Reputation DESC, H.VoteCount DESC NULLS LAST
OFFSET 0 LIMIT 10;
