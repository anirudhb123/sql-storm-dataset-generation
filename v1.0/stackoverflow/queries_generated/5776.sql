WITH UserBadges AS (
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
),
ActiveUsers AS (
    SELECT 
        UserId, 
        COUNT(P.Id) AS PostsCount, 
        SUM(P.Score) AS TotalScore, 
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        UserId
),
UserStats AS (
    SELECT 
        UB.UserId, 
        UB.DisplayName, 
        UB.BadgeCount AS TotalBadges, 
        COALESCE(AU.PostsCount, 0) AS RecentPosts, 
        COALESCE(AU.TotalScore, 0) AS RecentScore, 
        COALESCE(AU.AvgViewCount, 0) AS AvgViewCount
    FROM 
        UserBadges UB
    LEFT JOIN 
        ActiveUsers AU ON UB.UserId = AU.UserId
    WHERE 
        UB.BadgeCount > 0
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.TotalBadges, 
    U.RecentPosts, 
    U.RecentScore, 
    U.AvgViewCount
FROM 
    UserStats U
ORDER BY 
    U.TotalBadges DESC, 
    U.RecentScore DESC
LIMIT 10;

