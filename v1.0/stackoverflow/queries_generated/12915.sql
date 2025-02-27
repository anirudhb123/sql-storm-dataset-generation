-- Performance benchmarking query for Stack Overflow schema
-- This query retrieves the count of posts, comments, and users, along with their average scores and vote counts

SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT AVG(Score) FROM Posts) AS AvgPostScore,
    (SELECT AVG(Score) FROM Comments) AS AvgCommentScore,
    (SELECT SUM(UpVotes) FROM Users) AS TotalUpVotes,
    (SELECT SUM(DownVotes) FROM Users) AS TotalDownVotes,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges
;
