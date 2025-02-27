-- Performance Benchmarking Query
-- This query retrieves the number of posts, comments, and users, along with the average reputation of users,
-- to help gauge performance metrics in terms of post interactions and user engagement.

SELECT
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT AVG(Reputation) FROM Users) AS AverageUserReputation,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(DISTINCT PostId) FROM Votes) AS TotalVotedPosts
FROM
    DUAL; -- Replace DUAL with appropriate table or syntax for your SQL environment if necessary.
