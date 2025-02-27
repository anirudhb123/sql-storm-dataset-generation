WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        0 AS Depth
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        URC.Depth + 1
    FROM 
        Users U
    JOIN 
        UserReputationCTE URC ON U.Reputation < URC.Reputation
    WHERE 
        URC.Depth < 5
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LatestPost
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
BadgeStatistics AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        URC.Reputation,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.AverageScore,
        PS.LatestPost,
        BS.TotalBadges,
        BS.GoldBadges,
        BS.SilverBadges,
        BS.BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        UserReputationCTE URC ON U.Id = URC.Id
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        BadgeStatistics BS ON U.Id = BS.UserId
    WHERE 
        U.LastAccessDate > NOW() - INTERVAL '1 YEAR'
)
SELECT 
    AU.UserId,
    AU.DisplayName,
    COALESCE(AU.Reputation, 0) AS Reputation,
    COALESCE(AU.TotalPosts, 0) AS TotalPosts,
    COALESCE(AU.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(AU.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(AU.AverageScore, 0) AS AverageScore,
    AU.LatestPost,
    COALESCE(AU.TotalBadges, 0) AS TotalBadges,
    COALESCE(AU.GoldBadges, 0) AS GoldBadges,
    COALESCE(AU.SilverBadges, 0) AS SilverBadges,
    COALESCE(AU.BronzeBadges, 0) AS BronzeBadges
FROM 
    ActiveUsers AU
ORDER BY 
    AU.Reputation DESC, 
    AU.TotalPosts DESC
LIMIT 100;
