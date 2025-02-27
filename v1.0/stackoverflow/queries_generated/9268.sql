WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(B.Class = 1)::int AS GoldBadges,
        SUM(B.Class = 2)::int AS SilverBadges,
        SUM(B.Class = 3)::int AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        U.Id
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
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserStats
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
