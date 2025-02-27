
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT AVG(Reputation) FROM Users) AS AverageUserReputation,
    (SELECT AVG(ViewCount) FROM Posts) AS AveragePostViewCount,
    (SELECT COUNT(DISTINCT PostTypeId) FROM Posts) AS DistinctPostTypes,
    (SELECT COUNT(DISTINCT VoteTypeId) FROM Votes) AS DistinctVoteTypes,
    (SELECT COUNT(DISTINCT TagName) FROM Tags) AS DistinctTags
FROM 
    Posts, Comments, Votes, Users, Tags
GROUP BY 
    (SELECT COUNT(*) FROM Posts),
    (SELECT COUNT(*) FROM Comments),
    (SELECT COUNT(*) FROM Votes),
    (SELECT COUNT(*) FROM Users),
    (SELECT AVG(Reputation) FROM Users),
    (SELECT AVG(ViewCount) FROM Posts),
    (SELECT COUNT(DISTINCT PostTypeId) FROM Posts),
    (SELECT COUNT(DISTINCT VoteTypeId) FROM Votes),
    (SELECT COUNT(DISTINCT TagName) FROM Tags);
