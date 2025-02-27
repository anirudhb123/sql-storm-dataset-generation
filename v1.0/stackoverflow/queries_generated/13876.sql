-- Performance Benchmarking SQL Query

-- This query aims to benchmark the performance of retrieving user activities and their associated posts, votes, and comments.
-- It joins multiple tables to analyze the relationships and counts within the user activity on Stack Overflow.

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    UserId, 
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalVotes,
    TotalUpVotes,
    TotalDownVotes
FROM 
    UserActivity
ORDER BY 
    TotalVotes DESC, TotalPosts DESC;
