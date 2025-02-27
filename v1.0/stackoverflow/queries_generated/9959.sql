WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.UserId IS NOT NULL AND V.VoteTypeId = 2) AS UpVoteCount,
        SUM(V.UserId IS NOT NULL AND V.VoteTypeId = 3) AS DownVoteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgPostScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
UserComprehensiveStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.AvgPostScore, 0) AS AvgPostScore,
        COALESCE(P.TotalViews, 0) AS TotalViews,
        UA.PostCount,
        UA.CommentCount,
        UA.BadgeCount,
        UA.UpVoteCount,
        UA.DownVoteCount
    FROM UserActivity UA
    LEFT JOIN PostStatistics P ON UA.UserId = P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.CommentCount,
    U.BadgeCount,
    U.UpVoteCount,
    U.DownVoteCount,
    U.TotalPosts,
    U.AvgPostScore,
    U.TotalViews
FROM UserComprehensiveStats U
ORDER BY U.TotalPosts DESC, U.PostCount DESC
LIMIT 100;
