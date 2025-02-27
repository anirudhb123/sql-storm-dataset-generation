
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS GoldBadges,
        COUNT(B.Id) AS SilverBadges,
        COUNT(B.Id) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
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
        P.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
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
        UserBadges B ON U.Id = B.UserId
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
