WITH UserBagdes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostScoreCTE AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.TotalScore, 0) AS TotalScore,
        COALESCE(P.AverageScore, 0) AS AverageScore,
        COALESCE(B.GoldBadges, 0) AS GoldBadges,
        COALESCE(B.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        PostScoreCTE P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        UserBaddes B ON U.Id = B.UserId
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalPosts,
    T.TotalScore,
    T.AverageScore,
    T.GoldBadges,
    T.SilverBadges,
    T.BronzeBadges,
    RANK() OVER (ORDER BY T.TotalScore DESC) AS ScoreRank
FROM 
    TopUsers T
WHERE 
    T.TotalPosts > 0
ORDER BY 
    T.TotalScore DESC, T.DisplayName ASC
LIMIT 10;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        PH.Level + 1
    FROM 
        Posts P
    JOIN 
        PostHierarchy PH ON P.ParentId = PH.Id
)
SELECT 
    * 
FROM 
    PostHierarchy
WHERE 
    Level = 2;
