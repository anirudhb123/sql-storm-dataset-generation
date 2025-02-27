WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostFrequency
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    ORDER BY PostFrequency DESC
    LIMIT 10
),
UserScore AS (
    SELECT
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.CommentCount,
        UA.TotalBounty,
        UA.TotalUpvotes,
        UA.TotalDownvotes,
        UA.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC, UA.PostCount DESC) AS Ranking
    FROM UserActivity UA
)

SELECT 
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.CommentCount,
    US.TotalBounty,
    US.TotalUpvotes,
    US.TotalDownvotes,
    US.BadgeCount,
    PT.TagName,
    PT.PostFrequency
FROM UserScore US
JOIN PopularTags PT ON PT.PostFrequency > 5
WHERE US.Ranking <= 50
ORDER BY US.Reputation DESC, US.PostCount DESC;
