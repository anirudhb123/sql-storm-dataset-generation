WITH UsersBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), UserPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
), UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.Views AS UserViews,
        U.LastAccessDate,
        U.CreationDate,
        COALESCE(UBC.BadgeCount, 0) AS TotalBadges,
        COALESCE(UPS.TotalPosts, 0) AS PostCount,
        COALESCE(UPS.PositiveScorePosts, 0) AS PositivePosts,
        COALESCE(UPS.TotalViews, 0) AS PostViews
    FROM 
        Users U
    LEFT JOIN 
        UsersBadgeCount UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        UserPostStats UPS ON U.Id = UPS.OwnerUserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.UserViews,
    UA.TotalBadges,
    UA.PostCount,
    UA.PositivePosts,
    UA.PostViews,
    RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank
FROM 
    UserActivity UA
WHERE 
    UA.Reputation > 1000
    AND UA.TotalBadges > 0
    AND UA.LastAccessDate >= DATEADD(year, -1, GETDATE())
ORDER BY 
    UA.Reputation DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
