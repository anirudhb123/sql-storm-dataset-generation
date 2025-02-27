WITH CTE_UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
CTE_PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        AVG(P.ViewCount) AS AvgViews,
        MAX(P.CreationDate) AS MostRecentPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CTE_MostActiveUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        CTE_PostStats
),
CTE_UserPostBadgeStats AS (
    SELECT 
        U.UserId,
        U.Reputation,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(P.TotalAnswers, 0) AS TotalAnswers,
        B.BadgeCount,
        B.GoldBadges,
        B.SilverBadges,
        B.BronzeBadges
    FROM 
        CTE_UserStats B
    LEFT JOIN 
        CTE_PostStats P ON B.UserId = P.OwnerUserId
    )
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    CASE 
        WHEN U.Reputation > 10000 THEN 'High Reputation'
        WHEN U.Reputation BETWEEN 5000 AND 10000 THEN 'Moderate Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    P.PostRank
FROM 
    CTE_UserPostBadgeStats U
FULL OUTER JOIN 
    CTE_MostActiveUsers P ON U.UserId = P.UserId
WHERE 
    (U.TotalPosts IS NOT NULL OR P.PostRank IS NOT NULL)
    AND (U.BadgeCount IS NULL OR U.BadgeCount >= 5)
ORDER BY 
    COALESCE(U.TotalPosts, 0) DESC, 
    COALESCE(U.BadgeCount, 0) DESC;
