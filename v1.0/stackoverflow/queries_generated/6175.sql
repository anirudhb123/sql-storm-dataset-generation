WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostsCreated,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
)
SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalUpvotes,
    UA.TotalDownvotes,
    UA.TotalBadges,
    PS.PostsCreated,
    PS.TotalScore,
    PS.AverageViewCount,
    PS.LastPostDate
FROM UserActivity UA
JOIN PostStats PS ON UA.UserId = PS.OwnerUserId
ORDER BY UA.TotalUpvotes DESC, UA.TotalPosts DESC
LIMIT 100;
