-- Performance Benchmarking Query

WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS TotalQuestionScore,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        PT.Name AS PostType,
        COUNT(C.Id) AS TotalComments
    FROM Posts P
    LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.FavoriteCount, PT.Name
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.TotalPosts,
    U.TotalViews,
    U.TotalScore,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.AnswerCount,
    P.CommentCount AS PostCommentCount,
    P.FavoriteCount AS PostFavoriteCount,
    P.PostType,
    P.TotalComments
FROM UserStatistics U
JOIN PostStatistics P ON U.UserId = P.OwnerUserId
ORDER BY U.Reputation DESC, P.ViewCount DESC
LIMIT 100;
