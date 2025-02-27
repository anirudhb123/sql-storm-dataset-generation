
SELECT
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT AVG(Reputation) FROM Users) AS AverageUserReputation,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(DISTINCT PostId) FROM Votes) AS TotalVotedPosts
GROUP BY
    (SELECT COUNT(*) FROM Posts),
    (SELECT COUNT(*) FROM Comments),
    (SELECT COUNT(*) FROM Users),
    (SELECT AVG(Reputation) FROM Users),
    (SELECT COUNT(*) FROM Badges),
    (SELECT COUNT(*) FROM Votes),
    (SELECT COUNT(DISTINCT PostId) FROM Votes);
