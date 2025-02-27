WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
TopPosters AS (
    SELECT 
        UserId, 
        Reputation, 
        PostCount,
        CommentCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserReputation
),
ActiveUsers AS (
    SELECT 
        UserId,
        COUNT(DISTINCT V.Id) AS VoteCount,
        AVG(V.BountyAmount) AS AvgBountyAmount
    FROM 
        Votes V
    GROUP BY 
        UserId
),
FinalUserStats AS (
    SELECT 
        T.UserId,
        T.Reputation,
        T.PostCount,
        T.CommentCount,
        T.GoldBadges,
        T.SilverBadges,
        T.BronzeBadges,
        A.VoteCount,
        A.AvgBountyAmount
    FROM 
        TopPosters T
    LEFT JOIN 
        ActiveUsers A ON T.UserId = A.UserId
)
SELECT 
    F.UserId,
    F.Reputation,
    F.PostCount,
    F.CommentCount,
    F.GoldBadges,
    F.SilverBadges,
    F.BronzeBadges,
    COALESCE(F.VoteCount, 0) AS VoteCount,
    COALESCE(F.AvgBountyAmount, 0) AS AvgBountyAmount,
    ROW_NUMBER() OVER (ORDER BY F.Reputation DESC) AS ReputationRank
FROM 
    FinalUserStats F
WHERE 
    F.PostCount > 10
    AND F.VoteCount > 5
ORDER BY 
    ReputationRank
LIMIT 50;
