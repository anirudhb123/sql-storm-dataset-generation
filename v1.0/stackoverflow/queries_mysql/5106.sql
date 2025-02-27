
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.Views,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        @rank := IF(@prevReputation = U.Reputation, @rank, @rank + 1) AS ReputationRank,
        @prevReputation := U.Reputation
    FROM Users U
    JOIN UserBadges UB ON U.Id = UB.UserId
    CROSS JOIN (SELECT @rank := 0, @prevReputation := NULL) AS vars
    WHERE U.Reputation > 1000
    ORDER BY U.Reputation DESC
),
PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.OwnerUserId
    HAVING COUNT(V.Id) > 10
),
UserTopPosts AS (
    SELECT 
        U.DisplayName,
        PP.Title,
        PP.Score,
        PP.VoteCount,
        @postRank := IF(@prevUserId = U.Id, @postRank + 1, 1) AS PostRank,
        @prevUserId := U.Id
    FROM TopUsers U
    JOIN PopularPosts PP ON U.Id = PP.OwnerUserId
    CROSS JOIN (SELECT @postRank := 0, @prevUserId := NULL) AS vars
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    P.Title AS TopPostTitle,
    P.Score AS PostScore,
    P.VoteCount AS PostVoteCount
FROM TopUsers U
JOIN UserTopPosts P ON U.DisplayName = P.DisplayName
WHERE P.PostRank = 1
ORDER BY U.Reputation DESC;
