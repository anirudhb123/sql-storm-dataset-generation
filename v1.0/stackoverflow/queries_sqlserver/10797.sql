
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT AVG(Reputation) FROM Users) AS AverageReputation,
    (SELECT MAX(CreationDate) FROM Posts) AS LatestPostCreationDate
GROUP BY
    (SELECT COUNT(*) FROM Posts),
    (SELECT COUNT(*) FROM Users),
    (SELECT COUNT(*) FROM Votes),
    (SELECT AVG(Reputation) FROM Users),
    (SELECT MAX(CreationDate) FROM Posts);
