-- Performance benchmarking SQL query

-- 1. Count the total number of users
SELECT COUNT(*) AS TotalUsers
FROM Users;

-- 2. Count the total number of posts categorized by PostTypeId
SELECT PostTypeId, COUNT(*) AS TotalPosts
FROM Posts
GROUP BY PostTypeId;

-- 3. Calculate the average reputation of users
SELECT AVG(Reputation) AS AverageReputation
FROM Users;

-- 4. Fetch the top 5 users with the highest reputation
SELECT TOP 5 Id, DisplayName, Reputation
FROM Users
ORDER BY Reputation DESC;

-- 5. Count the number of votes per post type
SELECT p.PostTypeId, COUNT(v.Id) AS TotalVotes
FROM Posts p
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY p.PostTypeId;

-- 6. Retrieve the top 10 most viewed posts
SELECT Id, Title, ViewCount
FROM Posts
ORDER BY ViewCount DESC
LIMIT 10;

-- 7. Count the number of comments for each post
SELECT PostId, COUNT(*) AS TotalComments
FROM Comments
GROUP BY PostId;

-- 8. Retrieve badge information for users with the highest reputation
SELECT u.Id, u.DisplayName, b.Name, b.Class
FROM Users u
JOIN Badges b ON u.Id = b.UserId
WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY u.Reputation DESC;

-- 9. Aggregate close reasons from PostHistory
SELECT ph.PostHistoryTypeId, COUNT(*) AS TotalCloseActions
FROM PostHistory ph
WHERE ph.PostHistoryTypeId IN (10, 11) -- Close or Reopen
GROUP BY ph.PostHistoryTypeId;

-- 10. Average score of posts per post type
SELECT p.PostTypeId, AVG(p.Score) AS AverageScore
FROM Posts p
GROUP BY p.PostTypeId;
