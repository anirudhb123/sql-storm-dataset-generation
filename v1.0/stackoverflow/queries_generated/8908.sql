WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        COUNT(DISTINCT B.Id) AS BadgesCount,
        SUM(V.CreationDate >= NOW() - INTERVAL '30 days') AS RecentVotesCount,
        SUM(CASE WHEN P.CreationDate >= NOW() - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPostsCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostsCount,
        CommentsCount,
        BadgesCount,
        RecentVotesCount,
        RecentPostsCount,
        RANK() OVER (ORDER BY PostsCount DESC, CommentsCount DESC, BadgesCount DESC) as Rank
    FROM UserActivity
),
ActiveTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsWithTagCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.Id
    HAVING COUNT(DISTINCT P.Id) > 10
)
SELECT 
    TU.DisplayName,
    TU.PostsCount,
    TU.CommentsCount,
    TU.BadgesCount,
    TU.RecentVotesCount,
    TU.RecentPostsCount,
    AT.TagName,
    AT.PostsWithTagCount
FROM TopUsers TU
JOIN ActiveTags AT ON AT.PostsWithTagCount > 0
WHERE TU.Rank <= 10
ORDER BY TU.Rank, AT.PostsWithTagCount DESC;
