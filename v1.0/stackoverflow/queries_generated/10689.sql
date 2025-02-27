-- Performance Benchmarking Query

-- This query retrieves the count of posts, users, comments, and votes 
-- along with the average score of the posts to assess the performance 
-- of various tables in the StackOverflow schema.

SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    AVG(Score) AS AveragePostScore
FROM 
    Posts;
