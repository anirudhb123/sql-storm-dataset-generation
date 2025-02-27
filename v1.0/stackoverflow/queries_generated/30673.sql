WITH RECURSIVE UserReputationHistory AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        1 AS RankLevel
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
    UNION ALL
    SELECT 
        U.Id,
        U.Reputation + 50 AS Reputation,
        U.CreationDate,
        U.DisplayName,
        URH.RankLevel + 1 AS RankLevel
    FROM 
        Users U
    JOIN 
        UserReputationHistory URH ON U.Id = URH.UserId
    WHERE 
        URH.RankLevel < 5 -- Limiting to 5 recursive levels
)
, RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > NOW() - INTERVAL '30 days'
)
, UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(URH.RankLevel, 0) AS ReputationRank,
    RP.PostId,
    RP.Title AS RecentPostTitle,
    RP.Score AS PostScore,
    UB.TotalBadges,
    UB.BadgeNames
FROM 
    Users U
LEFT JOIN 
    UserReputationHistory URH ON U.Id = URH.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.PostRank = 1
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
WHERE 
    (U.Reputation > 1000 OR UB.TotalBadges > 5) -- Filter condition
ORDER BY 
    U.Reputation DESC, UB.TotalBadges DESC
LIMIT 50;

This SQL query achieves the following:
1. Utilizes a recursive CTE to establish a user reputation history, demonstrating computed values based on the original user reputation.
2. Aggregates recent posts from the last 30 days using another CTE, incorporating window functions (`ROW_NUMBER()`) to rank posts.
3. Joins badge information, displaying both the total number of badges and their names as a concatenated string.
4. Applies filtering to select users with a reputation greater than 1000 or those with more than 5 badges.
5. Finally, results are ordered by reputation and badges, limiting the output to 50 entries to benchmark performance.
