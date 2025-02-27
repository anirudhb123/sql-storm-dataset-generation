
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty,
        @rank1 := IF(@prevRep = Reputation, @rank1, @rownum) AS ReputationRank,
        @prevRep := Reputation,
        @rownum := @rownum + 1
    FROM 
        UserStats, 
        (SELECT @rownum := 0, @rank1 := 0, @prevRep := NULL) r
    ORDER BY 
        Reputation DESC
),
CombinedRanks AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty,
        (ReputationRank + PostsRank) AS CombinedRank
    FROM (
        SELECT 
            UserId,
            DisplayName,
            Reputation,
            TotalPosts,
            TotalQuestions,
            TotalAnswers,
            TotalBounty,
            @rank2 := IF(@prevPosts = TotalPosts, @rank2, @rownum2) AS PostsRank,
            @prevPosts := TotalPosts,
            @rownum2 := @rownum2 + 1
        FROM 
            TopUsers, 
            (SELECT @rownum2 := 0, @rank2 := 0, @prevPosts := NULL) r
        ORDER BY 
            TotalPosts DESC
    ) AS RankedPosts
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalBounty,
    CombinedRank
FROM 
    CombinedRanks
WHERE 
    CombinedRank <= 10
ORDER BY 
    CombinedRank;
