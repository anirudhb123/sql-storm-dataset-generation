WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserPostAnalytics AS (
    SELECT 
        RU.UserId,
        RU.DisplayName,
        RU.Reputation,
        RU.TotalPosts,
        RU.TotalComments,
        RU.GoldBadges,
        RU.SilverBadges,
        RU.BronzeBadges,
        P.Title AS RecentPostTitle,
        P.CreationDate AS RecentPostDate,
        P.ViewCount AS RecentPostViews,
        P.Score AS RecentPostScore
    FROM 
        RankedUsers RU
    LEFT JOIN 
        Posts P ON RU.UserId = P.OwnerUserId
    WHERE 
        P.CreationDate = (
            SELECT MAX(P2.CreationDate)
            FROM Posts P2
            WHERE P2.OwnerUserId = RU.UserId
        )
),
UserActivity AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.TotalPosts,
        UA.TotalComments,
        UA.GoldBadges,
        UA.SilverBadges,
        UA.BronzeBadges,
        SUM(V.BountyAmount) AS TotalBountyEarned,
        (SELECT COUNT(*) FROM Votes V2 WHERE V2.UserId = UA.UserId) AS TotalVotes
    FROM 
        UserPostAnalytics UA
    LEFT JOIN 
        Votes V ON UA.UserId = V.UserId
    GROUP BY 
        UA.UserId, UA.DisplayName, UA.Reputation, UA.TotalPosts, UA.TotalComments, UA.GoldBadges, UA.SilverBadges, UA.BronzeBadges
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.TotalPosts,
    UA.TotalComments,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    UA.TotalBountyEarned,
    UA.TotalVotes,
    RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank
FROM 
    UserActivity UA
ORDER BY 
    UA.Reputation DESC
LIMIT 10;
