WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    
    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        CTE.Level + 1
    FROM 
        Users U
    INNER JOIN 
        UserReputationCTE CTE ON U.Reputation > CTE.Reputation
    WHERE 
        U.Reputation > 1000
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
VoteCounts AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS PositiveVotes,
        SUM(CASE WHEN V.VoteTypeId IN (3, 10) THEN 1 ELSE 0 END) AS NegativeVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
    PS.PostCount,
    PS.TotalScore,
    PS.AvgViewCount,
    COALESCE(VC.PositiveVotes, 0) AS PositiveVotes,
    COALESCE(VC.NegativeVotes, 0) AS NegativeVotes,
    R.Level AS ReputationLevel
FROM 
    Users U
LEFT JOIN 
    UserBadges B ON U.Id = B.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    VoteCounts VC ON U.Id = VC.UserId
LEFT JOIN 
    UserReputationCTE R ON U.Id = R.Id
WHERE 
    U.Reputation > 5000
ORDER BY 
    U.Reputation DESC,
    PS.TotalScore DESC;
