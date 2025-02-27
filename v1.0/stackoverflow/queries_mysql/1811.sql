
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(IFNULL(V.BountyAmount, 0)) AS TotalBountySpent,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount, 
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
),
UserSummary AS (
    SELECT 
        UA.UserId, 
        UA.DisplayName, 
        UA.Reputation, 
        UA.TotalPosts, 
        UA.TotalComments, 
        UA.TotalBountySpent,
        UA.TotalViews,
        PS.Title AS RecentPostTitle,
        PS.Score AS RecentPostScore,
        PS.ViewCount AS RecentPostViews
    FROM UserActivity UA
    LEFT JOIN PostStats PS ON UA.UserId = PS.OwnerUserId
    WHERE UA.TotalPosts > 0
)
SELECT 
    US.*,
    CASE 
        WHEN US.Reputation >= 1000 THEN 'High Reputation'
        WHEN US.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationTier,
    CASE 
        WHEN US.TotalViews IS NULL THEN 'No Views Yet'
        ELSE CONCAT(US.TotalViews, ' Views')
    END AS ViewsInfo
FROM UserSummary US
ORDER BY US.TotalBountySpent DESC, US.Reputation DESC;
