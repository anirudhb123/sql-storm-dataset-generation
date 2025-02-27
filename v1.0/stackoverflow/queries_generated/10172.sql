-- Performance benchmarking query for the StackOverflow database schema
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.FavoriteCount,
        T.TagName
    FROM Posts P
    LEFT JOIN Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
),
BenchmarkStats AS (
    SELECT 
        UA.UserId,
        UA.Reputation,
        UA.PostCount,
        UA.TotalScore,
        UA.TotalCommentScore,
        UA.BadgeCount,
        UA.VoteCount,
        PS.PostId,
        PS.Title,
        PS.Score AS PostScore,
        PS.ViewCount,
        PS.AnswerCount,
        PS.FavoriteCount,
        PS.CreationDate,
        PS.TagName
    FROM UserActivity UA
    JOIN PostStats PS ON UA.PostCount > 0
)
SELECT 
    UserId,
    Reputation,
    COUNT(DISTINCT PostId) AS UniquePostCount,
    SUM(PostScore) AS TotalPostScore,
    AVG(ViewCount) AS AverageViewCount,
    AVG(AnswerCount) AS AverageAnswerCount,
    AVG(FavoriteCount) AS AverageFavoriteCount,
    STRING_AGG(DISTINCT TagName, ', ') AS TagsAssociated
FROM BenchmarkStats
GROUP BY UserId, Reputation
ORDER BY TotalPostScore DESC, UniquePostCount DESC;
