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
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserBadges
    JOIN 
        Users U ON UserBadges.UserId = U.Id
    WHERE 
        U.Reputation > 1000
),
MostActivePosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ActiveUserStats AS (
    SELECT 
        T.UserId,
        T.DisplayName,
        T.Reputation,
        T.BadgeCount,
        T.GoldBadges,
        T.SilverBadges,
        T.BronzeBadges,
        P.PostCount,
        P.TotalViews,
        P.TotalAnswers
    FROM 
        TopUsers T
    JOIN 
        MostActivePosts P ON T.UserId = P.OwnerUserId
)
SELECT 
    A.DisplayName,
    A.Reputation,
    A.BadgeCount,
    A.GoldBadges,
    A.SilverBadges,
    A.BronzeBadges,
    A.PostCount,
    A.TotalViews,
    A.TotalAnswers
FROM 
    ActiveUserStats A
WHERE 
    A.ReputationRank <= 10
ORDER BY 
    A.Reputation DESC, 
    A.PostCount DESC;
