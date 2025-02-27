
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalUpvotes,
        TotalDownvotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBadges,
        @rank := IF(@prev_rank = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_rank := Reputation
    FROM 
        UserStats, (SELECT @rank := 0, @prev_rank := NULL) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalUpvotes,
    TotalDownvotes,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalBadges,
    ReputationRank
FROM 
    RankedUsers
WHERE 
    TotalPosts > 10
ORDER BY 
    ReputationRank
LIMIT 50;
