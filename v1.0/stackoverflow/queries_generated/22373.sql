WITH RankedBadges AS (
    SELECT 
        B.UserId,
        B.Name AS BadgeName,
        B.Class,
        ROW_NUMBER() OVER (PARTITION BY B.UserId ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Badges B
), 
UserAggregates AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        RankedBadges RB ON U.Id = RB.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalClosedPosts
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
        AND PH.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        PH.UserId
)
SELECT 
    U.Id,
    U.DisplayName,
    COALESCE(UA.TotalBadges, 0) AS TotalBadges,
    COALESCE(UA.GoldBadges, 0) AS GoldBadges,
    COALESCE(UA.SilverBadges, 0) AS SilverBadges,
    COALESCE(UA.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(PS.AverageScore, 0) AS AverageScore,
    COALESCE(CP.TotalClosedPosts, 0) AS TotalClosedPosts
FROM 
    Users U
LEFT JOIN 
    UserAggregates UA ON U.Id = UA.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    ClosedPosts CP ON U.Id = CP.UserId
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND NOT EXISTS (
        SELECT 1 
        FROM Votes V 
        WHERE V.UserId = U.Id 
        AND V.VoteTypeId IN (3, 10) -- Considering downvotes and deletions
    )
ORDER BY 
    U.Reputation DESC, 
    U.DisplayName ASC
LIMIT 50;
