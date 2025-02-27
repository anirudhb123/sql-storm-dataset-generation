-- Performance Benchmarking Query

-- This query retrieves the total number of posts, users, and votes,
-- along with the average reputation of users and the latest post creation date.
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT AVG(Reputation) FROM Users) AS AverageReputation,
    (SELECT MAX(CreationDate) FROM Posts) AS LatestPostCreationDate
;
