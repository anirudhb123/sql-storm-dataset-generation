
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty,
        @rank := IF(@prevTotalPosts = TotalPosts AND @prevReputation = Reputation, @rank, @rank + 1) AS UserRank,
        @prevTotalPosts := TotalPosts,
        @prevReputation := Reputation
    FROM 
        UserStats,
        (SELECT @rank := 0, @prevTotalPosts := NULL, @prevReputation := NULL) AS vars
    ORDER BY 
        TotalPosts DESC, Reputation DESC
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty
    FROM 
        RankedUsers
    WHERE 
        UserRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalBounty,
    (SELECT 
        COUNT(*) 
     FROM 
        Comments C 
     WHERE 
        C.UserId = TU.UserId) AS TotalComments,
    (SELECT 
        COUNT(*) 
     FROM 
        Badges B 
     WHERE 
        B.UserId = TU.UserId AND B.Class = 1) AS GoldBadges,
    (SELECT 
        COUNT(*) 
     FROM 
        Badges B 
     WHERE 
        B.UserId = TU.UserId AND B.Class = 2) AS SilverBadges,
    (SELECT 
        COUNT(*) 
     FROM 
        Badges B 
     WHERE 
        B.UserId = TU.UserId AND B.Class = 3) AS BronzeBadges
FROM 
    TopUsers TU
ORDER BY 
    TU.TotalPosts DESC, TU.Reputation DESC;
