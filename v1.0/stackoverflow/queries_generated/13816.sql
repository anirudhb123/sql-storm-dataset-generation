-- Performance Benchmarking Query
-- This query retrieves a summary of the number of posts, comments, votes, and users,
-- as well as average reputation and view count for benchmarking purposes.

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

