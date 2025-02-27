
WITH UserBadgeSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN P.CreationDate >= NOW() - INTERVAL 1 YEAR THEN 1 ELSE 0 END) AS RecentPosts
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.NegativePosts, 0) AS NegativePosts,
        COALESCE(PS.RecentPosts, 0) AS RecentPosts,
        U.Reputation,
        U.CreationDate
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeSummary UBS ON U.Id = UBS.UserId
    LEFT JOIN 
        PostSummary PS ON U.Id = PS.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.GoldBadges,
        UA.SilverBadges,
        UA.BronzeBadges,
        UA.PostCount,
        UA.Reputation,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserActivity UA,
        (SELECT @row_num := 0) AS r
    WHERE 
        UA.Reputation > 1000 AND 
        UA.RecentPosts > 0
    ORDER BY 
        UA.Reputation DESC, UA.PostCount DESC
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.GoldBadges,
    A.SilverBadges,
    A.BronzeBadges,
    A.PostCount,
    A.Reputation,
    CASE 
        WHEN A.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorStatus,
    CASE 
        WHEN A.BronzeBadges > 0 THEN 'Promising Star'
        ELSE 'Newbie'
    END AS NewbieStatus
FROM 
    ActiveUsers A
ORDER BY 
    A.Rank
LIMIT 50 OFFSET 0;
