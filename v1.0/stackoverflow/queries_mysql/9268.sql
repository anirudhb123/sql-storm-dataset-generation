
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        TotalScore,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        @row_number := @row_number + 1 AS Rank
    FROM 
        UserStats, (SELECT @row_number := 0) AS rn
    ORDER BY 
        TotalScore DESC
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.Questions,
    TU.Answers,
    TU.TotalScore,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges
FROM 
    TopUsers TU
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Rank;
