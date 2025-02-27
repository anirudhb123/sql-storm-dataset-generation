WITH UserStatistics AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStatistics
),
PopularTags AS (
    SELECT 
        T.TagName,
        T.Count AS UsageCount
    FROM Tags T
    WHERE T.Count > 0
    ORDER BY T.Count DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalComments,
    TU.TotalBadges,
    PT.TagName,
    PT.UsageCount
FROM TopUsers TU
JOIN PopularTags PT ON TU.TotalPosts > 0
ORDER BY TU.Reputation DESC, PT.UsageCount DESC
LIMIT 50;
