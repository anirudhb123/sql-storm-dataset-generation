WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        BadgeCount,
        Rank
    FROM UserStats
    WHERE Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND PostCount > 5
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Owner
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year')
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.UpVotes,
    T.DownVotes,
    T.PostCount,
    T.CommentCount,
    T.BadgeCount,
    T.Rank,
    COUNT(P.PostId) AS RecentPosts,
    STRING_AGG(P.Title, ', ') AS RecentPostTitles
FROM TopUsers T
LEFT JOIN PostInfo P ON T.UserId = P.Owner
GROUP BY T.UserId, T.DisplayName, T.Reputation, T.UpVotes, T.DownVotes, 
         T.PostCount, T.CommentCount, T.BadgeCount, T.Rank
HAVING COUNT(P.PostId) > 0
ORDER BY T.Rank ASC;
