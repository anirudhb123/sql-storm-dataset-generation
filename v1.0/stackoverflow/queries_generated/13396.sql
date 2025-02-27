-- Performance benchmarking query for StackOverflow schema
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(B.Class) AS TotalBadgeCount,
        SUM(V.BountyAmount) AS TotalBountyAmount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.Tags,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
)
SELECT
    US.UserId,
    US.DisplayName,
    US.PostCount,
    US.CommentCount,
    US.TotalBadgeCount,
    US.TotalBountyAmount,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount AS PostCommentCount,
    PS.FavoriteCount,
    PS.Tags
FROM UserStats US
JOIN PostStats PS ON US.UserId = PS.OwnerUserId
ORDER BY US.TotalBountyAmount DESC, US.PostCount DESC;
