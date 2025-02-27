WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownvotes,
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
        u.Id
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
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
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
