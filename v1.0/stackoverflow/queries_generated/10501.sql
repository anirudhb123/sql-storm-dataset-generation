-- Performance benchmarking query that retrieves user statistics along with their post and vote details.

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0  -- Filter users with a positive reputation
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpvotes,
    us.TotalDownvotes,
    COALESCE(SUM(ph.Comment IS NOT NULL), 0) AS TotalPostEdits
FROM 
    UserStats us
LEFT JOIN 
    PostHistory ph ON us.UserId = ph.UserId
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.TotalPosts, us.TotalQuestions, us.TotalAnswers, us.TotalUpvotes, us.TotalDownvotes
ORDER BY 
    us.Reputation DESC;
