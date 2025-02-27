-- Performance benchmarking query: Retrieve the total number of Posts, Users, and average Reputation per User
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT AVG(Reputation) FROM Users) AS AverageReputation
UNION ALL
-- Retrieve the total number of votes and average score per post
SELECT 
    (SELECT SUM(Score) FROM Votes) AS TotalVotes,
    (SELECT AVG(Score) FROM Posts) AS AveragePostScore;
