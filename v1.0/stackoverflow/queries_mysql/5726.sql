
WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS VoteScore,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        @row_number := IF(@prev_post_type = P.PostTypeId, @row_number + 1, 1) AS PostRank,
        @prev_post_type := P.PostTypeId
    FROM Posts P
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR AND P.Score > 0
    ORDER BY P.PostTypeId, P.Score DESC, P.CreationDate DESC
),
PostDetails AS (
    SELECT 
        U.UserId,
        T.PostId,
        U.VoteScore,
        U.BadgeCount,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount
    FROM TopPosts T
    JOIN UserScore U ON T.OwnerUserId = U.UserId
    JOIN Posts P ON T.PostId = P.Id
    WHERE T.PostRank <= 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    P.Title AS PostTitle,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.VoteScore,
    P.BadgeCount,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.PostId) AS CommentCount
FROM PostDetails P
JOIN Users U ON P.UserId = U.Id
ORDER BY P.Score DESC, P.CreationDate DESC
LIMIT 50;
