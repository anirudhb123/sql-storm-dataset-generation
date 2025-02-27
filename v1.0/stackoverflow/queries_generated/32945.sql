WITH RECURSIVE UserHierarchy AS (
    SELECT Id, Reputation, DisplayName, CreationDate, 1 AS Level
    FROM Users
    WHERE Reputation > 1000 -- Start with users having more than 1000 reputation
    UNION ALL
    SELECT u.Id, u.Reputation, u.DisplayName, u.CreationDate, uh.Level + 1
    FROM Users u
    INNER JOIN UserHierarchy uh ON u.Reputation > uh.Reputation -- Join to populate hierarchy
    WHERE u.Id <> uh.Id
), 
PostStatistics AS (
    SELECT p.Id AS PostId, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(DISTINCT v.Id) AS VoteCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY p.Id
), 
UserPostStats AS (
    SELECT u.Id AS UserId, 
           u.DisplayName,
           COALESCE(SUM(ps.CommentCount), 0) AS TotalComments,
           COALESCE(SUM(ps.VoteCount), 0) AS TotalVotes,
           COALESCE(SUM(ps.UpVotes), 0) AS TotalUpVotes,
           COALESCE(SUM(ps.DownVotes), 0) AS TotalDownVotes,
           AVG(ps.AverageScore) AS AvgScore
    FROM Users u
    LEFT JOIN PostStatistics ps ON u.Id = ps.PostId
    WHERE u.Location IS NOT NULL -- Filter for users with specified location
    GROUP BY u.Id
)
SELECT uh.DisplayName,
       uh.Reputation,
       ups.TotalComments,
       ups.TotalVotes,
       ups.TotalUpVotes,
       ups.TotalDownVotes,
       ups.AvgScore
FROM UserHierarchy uh
LEFT JOIN UserPostStats ups ON uh.Id = ups.UserId
ORDER BY uh.Reputation DESC, ups.TotalVotes DESC
LIMIT 10;
