-- Performance Benchmarking Query

-- This query retrieves the total count of users, posts, comments, and votes
-- It also calculates the average reputation of users and the average score of posts

SELECT 
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT AVG(Reputation) FROM Users) AS AverageReputation,
    (SELECT AVG(Score) FROM Posts) AS AveragePostScore
FROM 
    dual;  -- replace 'dual' with an appropriate table if using a dialect other than Oracle
