-- Performance benchmarking query to summarize user activity and post statistics

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.TotalComments,
    u.TotalUpvotes,
    u.TotalDownvotes,
    (u.TotalUpvotes - u.TotalDownvotes) AS NetVotes
FROM 
    UserStats u
ORDER BY 
    Reputation DESC,
    TotalPosts DESC
LIMIT 100;  -- Limit the result to the top 100 users based on reputation
