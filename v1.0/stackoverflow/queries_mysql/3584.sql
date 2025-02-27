
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
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
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        @Rank := IF(@PrevOwnerUserId = P.OwnerUserId, @Rank + 1, 1) AS Rank,
        @PrevOwnerUserId := P.OwnerUserId
    FROM 
        Posts P, (SELECT @Rank := 0, @PrevOwnerUserId := NULL) AS vars
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        US.BadgeCount,
        US.GoldBadges,
        US.SilverBadges,
        US.BronzeBadges,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.TotalViews
    FROM 
        UserStats US
    JOIN 
        PostStats PS ON US.UserId = PS.OwnerUserId
    JOIN 
        Users U ON U.Id = US.UserId
)
SELECT 
    *,
    CASE 
        WHEN Reputation > 1000 THEN 'High Reputation'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationTier,
    CASE 
        WHEN TotalViews >= 10000 THEN 'Popular'
        ELSE 'Less Popular'
    END AS Popularity
FROM 
    CombinedStats
WHERE 
    QuestionCount > 0
ORDER BY 
    Reputation DESC, TotalViews DESC
LIMIT 10 OFFSET 10;
