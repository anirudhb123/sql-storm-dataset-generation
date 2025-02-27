-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        SUM(b.Class = 1) AS TotalGoldBadges,
        SUM(b.Class = 2) AS TotalSilverBadges,
        SUM(b.Class = 3) AS TotalBronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalUpVotes,
    TotalDownVotes,
    TotalGoldBadges,
    TotalSilverBadges,
    TotalBronzeBadges
FROM 
    UserStats
ORDER BY 
    TotalPosts DESC
LIMIT 10;
