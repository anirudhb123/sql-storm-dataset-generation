WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PopularityRank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1
),
TrendingTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS TrendRank
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalAnswers,
    US.TotalUpvotes,
    US.TotalDownvotes,
    PP.Title AS PopularPostTitle,
    PP.Score AS PopularPostScore,
    PP.ViewCount AS PopularPostViews,
    TT.TagName AS TrendingTag,
    TT.PostCount AS TrendingPostCount
FROM UserStats US
LEFT JOIN PopularPosts PP ON US.UserId = (SELECT OwnerUserId FROM Posts ORDER BY Score DESC, ViewCount DESC LIMIT 1) 
LEFT JOIN TrendingTags TT ON US.TotalPosts >= 5
WHERE US.Reputation > 100
ORDER BY US.TotalPosts DESC, US.TotalUpvotes DESC
LIMIT 50;
